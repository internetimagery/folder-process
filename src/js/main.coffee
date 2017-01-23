# Run the webpage!
console.log "Running Main.js"

# Send messages to the console
message = document.getElementById "console"

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

  for f in e.dataTransfer.files
    console.log f

  return false
