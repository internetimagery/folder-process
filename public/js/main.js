(function() {
  var ProgressBar, alertify, compress, drag_drop, fs, progress_indicator, progress_move;

  console.log("Running Main.js");

  alertify = require("alertifyjs");

  compress = require("./js/compress.js");

  fs = require('fs');

  ProgressBar = require("progressbar.js");

  progress_indicator = new ProgressBar.Circle("#progress", {
    color: "#FFFFFF",
    strokeWidth: 2.1
  });

  this.drop_enabled = true;

  progress_move = (function(_this) {
    return function(prog) {
      if (prog < 1) {
        return progress_indicator.animate(prog);
      } else {
        progress_indicator.set(0);
        drag_drop.className = "ready";
        _this.drop_enabled = true;
        return alertify.confirm("Compressing and Renaming complete! :)\nBe sure to compare the files with the originals.");
      }
    };
  })(this);

  drag_drop = document.getElementById("drop");

  drag_drop.ondragover = (function(_this) {
    return function() {
      if (_this.drop_enabled) {
        drag_drop.className = "drag";
      }
      return false;
    };
  })(this);

  drag_drop.ondragleave = function() {
    drag_drop.className = "ready";
    return false;
  };

  drag_drop.ondragend = function() {
    drag_drop.className = "ready";
    return false;
  };

  drag_drop.ondrop = (function(_this) {
    return function(e) {
      var current_progress, file, fn, i, len, multiplier, ref;
      e.preventDefault();
      if (_this.drop_enabled) {
        if (e.dataTransfer.files.length) {
          drag_drop.className = "disabled";
          _this.drop_enabled = false;
          multiplier = 1.0 / e.dataTransfer.files.length;
          progress_indicator.set(0);
          current_progress = 0;
          ref = e.dataTransfer.files;
          fn = function(file) {
            return fs.stat(file.path, function(err, stats) {
              if (stats.isDirectory()) {
                return compress.get_candidates(file.path, function(err, candidates) {
                  var step;
                  if (!candidates.length) {
                    current_progress += multiplier;
                    progress_move(current_progress);
                    return alertify.notify("Nothing to compress! :)");
                  } else {
                    step = 1 / candidates.length;
                    return compress.main(file.path, candidates, function(err, message) {
                      current_progress += step;
                      progress_move(current_progress);
                      if (err) {
                        console.error(err);
                        return alertify.error(err.message);
                      } else {
                        console.log(message);
                        return alertify.notify(message);
                      }
                    });
                  }
                });
              } else {
                return alertify.warning(file.name + " is not a folder.", function() {});
              }
            });
          };
          for (i = 0, len = ref.length; i < len; i++) {
            file = ref[i];
            fn(file);
          }
        }
      }
      return false;
    };
  })(this);

}).call(this);
