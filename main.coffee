
alertify = require 'alertify.js'
ProgressBar = require "progressbar.js"
Promise = require 'promise'
path = require 'path'
fs = require './lib/fs'
dragDrop = require "./lib/dragndrop"
compress = require "./lib/compress"
naming = require "./lib/naming"
reduce = Promise.denodeify require "async/reduce"
each = Promise.denodeify require "async/each"

# Simple progress indicator
progress_indicator = new ProgressBar.Circle "#progress",
  color: "#FFFFFF"
  strokeWidth: 2.1

# Report progress
progress_move = (prog)->
  console.log prog
#   if prog < 1
#     progress_indicator.animate prog
#   else
#     progress_indicator.set 0
#     drag_drop.className = "ready"
#     @drop_enabled = true
#     alertify.confirm "Compressing and Renaming complete! :)\nBe sure to compare the files with the originals."

# Process our files!
process = (paths)->

  # Reduce any requested paths to just directories.
  reduce paths, [], (ok, p, done)->
    fs.stat p.path
    .then (stats)->
      ok.push p.path if stats.isDirectory()
      done null, ok
    .catch done
  .then (dirs)->
    return alertify.alert "No folders given." if not dirs.length

    # Divide our progress up amongst the number of folders
    multiplier = 1.0 / dirs.length

    # Reset our progress indicator
    progress_move current_progress = 0

    # Lets run through the actual files!
    each dirs, (dir, done)->
      fs.readdir dir
      .then (files)->

        # Empty directory? Move on!
        if not files.length
          progress_move current_progress += multiplier
          return done()

        # Validate our files!
        naming.match dir
        .then (result)->
          move = naming.rename result.dir, result.fail, result.index
          console.log move
          done()
      .catch done



#               # We are ok to go! Get files!
#               compress.get_candidates file.path, (err, candidates)->
#                 if not candidates.length
#                   current_progress += multiplier
#                   progress_move current_progress
#                   alertify.notify "Nothing to compress! :)"
#                 else
#                   step = 1 / candidates.length
#                   compress.main file.path, candidates, (err, message)->
#                     current_progress += step
#                     progress_move current_progress
#                     if err
#                       console.error err
#                       alertify.error err.message
#                     else
#                       console.log message
#                       alertify.notify message
#             else
#               alertify.warning "#{file.name} is not a folder.", ()->
#
#   return false

# Set up dragging and dropping functionality
drop_enabled = true
dragDrop "#drop"
.on "over", (elem)->
  elem.className = "drag" if drop_enabled
.on "out", (elem)->
  elem.className = "ready"
.on "drop", (elem, files)->
  if drop_enabled
    drop_enabled = false
    elem.className = "disabled"
    process files
    .then ->
      elem.className = "ready"
      drop_enabled = true
      console.log "Done! :)"
      alertify.success "Done! :)"
    .catch (err)->
      elem.className = "ready"
      drop_enabled = true
      console.log "Oh no!"
      console.error err
      alertify.error err.name
