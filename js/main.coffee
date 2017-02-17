
dragDrop = require "./js/dragndrop"


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
    console.log "DROP"
    # do stuff
    drop_enabled = true

# # Run the webpage!
# console.log "Running Main.js"
#
# # Alert us when things happen!
# alertify = require "alertifyjs"
# compress = require "./js/compress.js"
# fs = require 'fs'
# ProgressBar = require "progressbar.js"
#
#
#
# # Display progress on progress bar
# progress_indicator = new ProgressBar.Circle "#progress",
#   color: "#FFFFFF"
#   strokeWidth: 2.1
#
# # Disable dropping while working
# @drop_enabled = true
#
# progress_move = (prog)=>
#   if prog < 1
#     progress_indicator.animate prog
#   else
#     progress_indicator.set 0
#     drag_drop.className = "ready"
#     @drop_enabled = true
#     alertify.confirm "Compressing and Renaming complete! :)\nBe sure to compare the files with the originals."
#
# # Allow drag and drop of folders to process
# drag_drop = document.getElementById "drop"
# drag_drop.ondragover = ()=>
#   if @drop_enabled
#     drag_drop.className = "drag"
#   return false
# drag_drop.ondragleave = ()->
#   drag_drop.className = "ready"
#   return false
# drag_drop.ondragend = ()->
#   drag_drop.className = "ready"
#   return false
# drag_drop.ondrop = (e)=>
#   e.preventDefault()
#   if @drop_enabled
#
#     if e.dataTransfer.files.length
#       drag_drop.className = "disabled"
#       @drop_enabled = false
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
