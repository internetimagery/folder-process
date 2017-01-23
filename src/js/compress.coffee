# Do the thing

fs = require 'fs'
path = require 'path'
mozjpeg = require 'mozjpeg'
ffmpeg = require 'ffmpeg-static'
child_process = require 'child_process'
escape_str = require "escape-string-regexp"


IMAGES = [".jpg", ".jpeg", ".png"]
VIDEO = [".mp4", ".mov", ".avi", ".wmv", ".rm", ".3gp", ".mkv", ".scm", ".vid", ".mpeg", ".avchd", ".m2ts"]
BACKUP_DIR = "Originals - Check before deleting" # Where to put original files


# Compress video to h264 with ffmpeg
compress_video = (src, dest, callback)->
  quality = 18 # 20 # Lower number, higher quality
  child_process.execFile ffmpeg.path, ["-v", "quiet", "-i", src, "-crf", quality, "-c:v", "libx264", dest], (err)->
    return callback err if err
    callback null

# Compress images with mozjpeg
compress_image = (src, dest, callback)->
  child_process.execFile mozjpeg, ["-outfile", dest, src], (err)->
    return callback err if err
    callback null

# Link a file to another file.
# If the other file exists. Check inode to see if the files are actually the same
safe_link = (src, dest, callback)->
  fs.link src, dest, (err)->
    if err
      # If the file already exists, that could be ok. If it's the same file
      if err.code == "EEXIST"
        fs.stat src, (err2, src_stats)->
          return callback err2 if err2
          fs.stat src, (err2, dest_stats)->
            return callback err2 if err2
            # Check if the two files are in fact the same.
            if src_stats.ino == dest_stats.ino
              callback null
            else
              # File exists, but is not the same file, so rethrow the error
              callback err
      else
        callback err
    else
      callback null

# Grab possible files we can use from the root directory
get_candidates = (root, callback)->
  fs.readdir root, (err, files)->
    return callback err if err

    num_start = 0 # Where do we start our file numbering?
    root_name = path.basename(root) # Name of folder
    tag_convention = /\[.+?\]/
    naming_convention = new RegExp escape_str(root_name) + "_(\\d+)"
    candidates = []

    # Look through file and grab files that don't match the naming convention
    # for media in (f f/or f in scandir(root) if f.is_file(follow_symlinks=False)):
    for m_name in files
        m_path = path.join root, m_name
        if fs.lstatSync(m_path).isFile()
          check = naming_convention.exec m_name # Check the file matches convention

          # If we have a file that matches the naming convention
          # then take the digit of the file as out new starting point.
          # We assume that a file matching naming conventions has already
          # been processed. So we leave it at that.
          if check?
            num_start = Math.max num_start, check[1]

          # We have a file that does not match the naming convention
          # so we assume it needs processing. Add it to our process list.
          else
            candidates.push {
              "o_name" : m_name
              "o_path" : m_path
            }

      # Figure out the number of zeros (padding) to use for Numbering
      num_zeroes = (num_start + candidates.length).toString().length
      if num_zeroes < 3
        num_zeroes = 3

      # Assemble a new name for each file
      for media in candidates
        num_start += 1

        num_str = num_start.toString()
        num_str = "0".repeat(num_zeroes - num_str.length) + num_str

        check = tag_convention.exec media.o_name
        tags = if check? then check[0] else ""

        ext = path.extname(media.o_name).toLowerCase()
        if ext in IMAGES
          media.type = 1
        else if ext in VIDEO
          media.type = 2
          ext = ".mp4" # Converting to mp4
        else
          media.type = 0

        media.n_name = "#{root_name}_#{num_str}#{tags}#{ext}"
        media.n_path = path.join root, media.n_name

      callback null, candidates


# Lets do it! Return (err, message)
this.main = (root, callback)->

  # Get a list of file names that do not match our naming convention.
  get_candidates root, (err, candidates)->
    return callback err if err

    # No candidates? Let us know that it's ok!
    if not candidates.length
      return callback null, "Nothing to compress."
    else
      b_dir = path.join root, BACKUP_DIR

      # Create backup directory
      fs.mkdir b_dir, (err)->
        return callback err if err? and err.code != "EEXIST"

        # Track and report our progress!
        total_files = candidates.length
        current_file = 0

        candidates.forEach (media)->
          media.b_path = path.join b_dir, media.o_name

          # Work out which compression type to use.
          # Compress into temporary working directory.
          # For unknown file type, simply link to working directory.
          compress_func = null
          switch media.type
            when 1 then compress_func = compress_image
            when 2 then compress_func = compress_video
            else compress_func = safe_link

          compress_func media.o_path, media.n_path, (err)->
            # If something went wrong with our compression, clean up
            if err
              return fs.unlink media.n_path, (err2)->
                callback err
                callback err2 if err2

            fs.stat media.o_path, (err, o_stat)->
              return callback err if err
              fs.stat media.n_path, (err, n_stat)->
                return callback err if err

                # Back up the original!
                safe_link media.o_path, media.b_path, (err)->
                  return callback err if err
                  fs.unlink media.o_path, (err)->
                    return callback err if err

                    # Compare the two sizes. If the compression did NOT shrink
                    # the file. Then just keep the original.
                    if n_stat.size < o_stat.size
                      current_file += 1
                      callback null, "[#{current_file}/#{total_files}] Compression complete: #{media.o_name} => #{media.n_name}"
                    else
                      fs.unlink media.n_path, (err)->
                        return callback err if err
                        safe_link media.b_path, media.n_path, (err)->
                          return callback err if err
                          current_file += 1
                          callback null, "[#{current_file}/#{total_files}] Compression unneeded: #{media.o_name} => #{media.n_name}"
              # DONE!
