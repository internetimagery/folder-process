# Simple progress bar!
ProgressBar = require 'progressbar.js'

module.exports = (element)->
  indicator = new ProgressBar.Circle element,
    color: "#FFFFFF"
    strokeWidth: 1

  # Function to set progress
  (prog)->
    prog = 1 if prog > 0.998
    prog = 0 if prog <= 0

    if 0 < prog <= 1
      indicator.animate prog
    else
      indicator.set 0
