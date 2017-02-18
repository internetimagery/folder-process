
alertify = require 'alertify.js'
ProgressBar = require "progressbar.js"
Promise = require 'promise'
path = require 'path'
fs = require './lib/fs'
dragDrop = require "./lib/dragndrop"
compress = require "./lib/compress"
naming = require "./lib/naming"
reduce = Promise.denodeify require "async/reduce"
eachLimit = Promise.denodeify require "async/eachLimit"

# How many tasks to run at once.
PROCESSES = 3

# Simple progress indicator
progress_indicator = new ProgressBar.Circle "#progress",
  color: "#FFFFFF"
  strokeWidth: 2.1

# Report progress
progress_move = (prog)->
  console.log "Progress!", "#{prog * 100}%"
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
    eachLimit dirs, 1, (dir, done)->
      fs.readdir dir
      .then (files)->

        # Empty directory? Move on!
        if not files.length
          progress_move current_progress += multiplier
          return done()

        # Validate our files!
        naming.match dir
        .then (result)->

          # Get some new file names
          move = naming.rename result.dir, result.fail, result.index

          # If all files are named correctly, move on!
          if not move.length
            progress_move current_progress += multiplier
            return done()

          # Further divide our progress
          segment = multiplier / move.length

          # Make a new folder to put our originals
          originals = path.join dir, "Originals Check before deleting #{Date.now()}"

          # Back up our original files!
          eachLimit move, PROCESSES, (m, fin)->
            origin = path.join dir, m.src
            backup = path.join originals, m.src
            compressed = path.join dir, m.dest
            start = Date.now()
            fs.ensureLink origin, backup
            .then ->
              compress origin, compressed
            .then ->
              progress_move current_progress += segment
              console.log "#{Date.now() - start} : #{m.src}"
              fs.remove origin
            .then fin
            .catch fin
          .then done
      .catch done

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
      progress_move 0
      console.log "Done! :)"
      alertify.success "Done! :)"
    .catch (err)->
      elem.className = "ready"
      drop_enabled = true
      progress_move 0
      console.log "Oh no!"
      console.error err
      alertify.error err.name
