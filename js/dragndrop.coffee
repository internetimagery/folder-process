# Drag and drop functionality!

module.exports = (element)->
  over = out = drop = null
  dragDrop = document.querySelector element
  dragDrop.ondragover = ()=>
    over dragDrop  if over?
    false
  dragDrop.ondragleave = ()->
    out dragDrop  if out?
    false
  dragDrop.ondragend = ()->
    out dragDrop  if out?
    false
  dragDrop.ondrop = (e)=>
    e.preventDefault()
    files = e.dataTransfer.files
    if files and files.length
      drop dragDrop, files if drop?
    else
      out dragDrop  if out?
    false
  @on = (event, func)=>
    switch event
      when "over" then over = func
      when "out" then out = func
      when "drop" then drop = func
    @
  @
