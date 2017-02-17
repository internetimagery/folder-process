
alertify = require 'alertify.js'
ProgressBar = require "progressbar.js"
Promise = require 'promise'
fs = require './js/fs'
dragDrop = require "./js/dragndrop"
compress = require "./js/compress"
reduce = Promise.denodeify require "async/reduce"

# Simple progress indicator
progress_indicator = new ProgressBar.Circle "#progress",
  color: "#FFFFFF"
  strokeWidth: 2.1

# Report progress
# progress_move = (prog)=>
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
      done ok
    .catch done
  .then (dirs)->
    return alertify.alert "No folders given." if not dirs.length
    # Divide our progress up amongst the number of folders
    multiplier = 1.0 / dirs.length

    # Reset our progress indicator
    progress_indicator.set 0


#
#       multiplier = 1.0 / e.dataTransfer.files.length
#       progress_indicator.set 0
#       current_progress = 0
#
#       for file in e.dataTransfer.files
#         do (file)->
#           fs.stat file.path, (err, stats)->
#             if stats.isDirectory()
#
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
      console.error err
      alertify.error err.name
