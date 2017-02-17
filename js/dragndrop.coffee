# Drag and drop functionality!

module.exports = (element)->
  dragDrop = document.querySelector element
  dragDrop.ondragover = ()=>
    false
  dragDrop.ondragleave = ()->
    false
  dragDrop.ondragend = ()->
    false
  dragDrop.ondrop = (e)=>
    e.preventDefault()
    files = e.dataTransfer.files
    if files and files.length
      console.log files
    false
