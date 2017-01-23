# Run the webpage!
console.log "Running Main.js"

# Alert us when things happen!
alertify = require "alertifyjs"
compress = require "./js/compress.js"
fs = require 'fs'
ProgressBar = require "progressbar.js"



# Display progress on progress bar
progress_indicator = new ProgressBar.Circle "#progress",
  color: "#FFFFFF"
  strokeWidth: 2.1

progress_move = (prog)->
  if prog < 1
    progress_indicator.animate prog
  else
    progress_indicator.set 0

# Allow drag and drop of folders to process
drag_drop = document.getElementById "drop"
drag_drop.ondragover = ()->
  drag_drop.className = "drag"
  return false
drag_drop.ondragleave = ()->
  drag_drop.className = "empty"
  return false
drag_drop.ondragend = ()->
  drag_drop.className = "empty"
  return false
drag_drop.ondrop = (e)->
  e.preventDefault()
  drag_drop.className = "empty"

  if e.dataTransfer.files.length

    multiplier = 1.0 / e.dataTransfer.files.length
    progress_indicator.set 0
    current_progress = 0

    for file in e.dataTransfer.files
      do (file)->
        fs.stat file.path, (err, stats)->
          if stats.isDirectory()

            # We are ok to go! Get files!
            compress.get_candidates file.path, (err, candidates)->
              if not candidates.length
                current_progress += multiplier
                progress_move current_progress
                alertify.notify "Nothing to compress! :)"
              else
                step = 1 / candidates.length
                compress.main file.path, candidates, (err, message)->
                  current_progress += step
                  progress_move current_progress
                  if err
                    console.error err
                    alertify.error err.message
                  else
                    console.log message
                    alertify.notify message
          else
            alertify.warning "#{file.name} is not a folder.", ()->

    return false
