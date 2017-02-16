(function() {
  var BACKUP_DIR, IMAGES, VIDEO, child_process, compress_image, compress_video, escape_str, ffmpeg, fs, mozjpeg, path, safe_link,
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  fs = require('fs');

  path = require('path');

  mozjpeg = require('mozjpeg');

  ffmpeg = require('ffmpeg-static');

  child_process = require('child_process');

  escape_str = require("escape-string-regexp");

  IMAGES = [".jpg", ".jpeg", ".png"];

  VIDEO = [".mp4", ".mov", ".avi", ".wmv", ".rm", ".3gp", ".mkv", ".scm", ".vid", ".mpeg", ".avchd", ".m2ts"];

  BACKUP_DIR = "Originals - Check before deleting";

  compress_video = function(src, dest, callback) {
    var quality;
    quality = 18;
    return child_process.execFile(ffmpeg.path, ["-v", "quiet", "-i", src, "-crf", quality, "-c:v", "libx264", dest], function(err) {
      if (err) {
        return callback(err);
      }
      return callback(null);
    });
  };

  compress_image = function(src, dest, callback) {
    return child_process.execFile(mozjpeg, ["-outfile", dest, src], function(err) {
      if (err) {
        return callback(err);
      }
      return callback(null);
    });
  };

  safe_link = function(src, dest, callback) {
    return fs.link(src, dest, function(err) {
      if (err) {
        if (err.code === "EEXIST") {
          return fs.stat(src, function(err2, src_stats) {
            if (err2) {
              return callback(err2);
            }
            return fs.stat(src, function(err2, dest_stats) {
              if (err2) {
                return callback(err2);
              }
              if (src_stats.ino === dest_stats.ino) {
                return callback(null);
              } else {
                return callback(err);
              }
            });
          });
        } else {
          return callback(err);
        }
      } else {
        return callback(null);
      }
    });
  };

  this.get_candidates = function(root, callback) {
    return fs.readdir(root, function(err, files) {
      var candidates, check, ext, i, j, len, len1, m_name, m_path, media, naming_convention, num_start, num_str, num_zeroes, root_name, tag_convention, tags;
      if (err) {
        return callback(err);
      }
      num_start = 0;
      root_name = path.basename(root);
      tag_convention = /\[.+?\]/;
      naming_convention = new RegExp(escape_str(root_name) + "_(\\d+)");
      candidates = [];
      for (i = 0, len = files.length; i < len; i++) {
        m_name = files[i];
        m_path = path.join(root, m_name);
        if (fs.lstatSync(m_path).isFile()) {
          check = naming_convention.exec(m_name);
          if (check != null) {
            num_start = Math.max(num_start, check[1]);
          } else {
            candidates.push({
              "o_name": m_name,
              "o_path": m_path
            });
          }
        }
      }
      num_zeroes = (num_start + candidates.length).toString().length;
      if (num_zeroes < 3) {
        num_zeroes = 3;
      }
      for (j = 0, len1 = candidates.length; j < len1; j++) {
        media = candidates[j];
        num_start += 1;
        num_str = num_start.toString();
        num_str = "0".repeat(num_zeroes - num_str.length) + num_str;
        check = tag_convention.exec(media.o_name);
        tags = check != null ? check[0] : "";
        ext = path.extname(media.o_name).toLowerCase();
        if (indexOf.call(IMAGES, ext) >= 0) {
          media.type = 1;
        } else if (indexOf.call(VIDEO, ext) >= 0) {
          media.type = 2;
          ext = ".mp4";
        } else {
          media.type = 0;
        }
        media.n_name = root_name + "_" + num_str + tags + ext;
        media.n_path = path.join(root, media.n_name);
      }
      return callback(null, candidates);
    });
  };

  this.main = function(root, candidates, callback) {
    var b_dir;
    b_dir = path.join(root, BACKUP_DIR);
    return fs.mkdir(b_dir, function(err) {
      var current_file, total_files;
      if ((err != null) && err.code !== "EEXIST") {
        return callback(err);
      }
      total_files = candidates.length;
      current_file = 0;
      return candidates.forEach(function(media) {
        var compress_func;
        media.b_path = path.join(b_dir, media.o_name);
        compress_func = null;
        switch (media.type) {
          case 1:
            compress_func = compress_image;
            break;
          case 2:
            compress_func = compress_video;
            break;
          default:
            compress_func = safe_link;
        }
        return compress_func(media.o_path, media.n_path, function(err) {
          if (err) {
            return fs.unlink(media.n_path, function(err2) {
              callback(err);
              if (err2) {
                return callback(err2);
              }
            });
          }
          return fs.stat(media.o_path, function(err, o_stat) {
            if (err) {
              return callback(err);
            }
            return fs.stat(media.n_path, function(err, n_stat) {
              if (err) {
                return callback(err);
              }
              return safe_link(media.o_path, media.b_path, function(err) {
                if (err) {
                  return callback(err);
                }
                return fs.unlink(media.o_path, function(err) {
                  if (err) {
                    return callback(err);
                  }
                  if (n_stat.size < o_stat.size) {
                    current_file += 1;
                    return callback(null, "[" + current_file + "/" + total_files + "] Compression complete: " + media.o_name + " => " + media.n_name);
                  } else {
                    return fs.unlink(media.n_path, function(err) {
                      if (err) {
                        return callback(err);
                      }
                      return safe_link(media.b_path, media.n_path, function(err) {
                        if (err) {
                          return callback(err);
                        }
                        current_file += 1;
                        return callback(null, "[" + current_file + "/" + total_files + "] Compression unneeded: " + media.o_name + " => " + media.n_name);
                      });
                    });
                  }
                });
              });
            });
          });
        });
      });
    });
  };

}).call(this);
