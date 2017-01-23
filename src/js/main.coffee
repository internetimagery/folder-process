# Run the webpage!
console.log "Running Main.js"

# Alert us when things happen!
alertify = require "alertifyjs"
compress = require "./js/compress.js"
fs = require 'fs'

# Display progress on progress bar
progress = document.getElementById "progress"

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

    for file in e.dataTransfer.files
      do (file)->
        fs.stat file.path, (err, stats)->
          if stats.isDirectory()

            console.log file.name
          else
            alertify.warning "#{file.name} is not a folder.", ()->

    return false
