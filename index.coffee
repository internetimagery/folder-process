# Process things in a folder

path = require 'path'
fs = require 'fs'
compress = require "./compress.js"

# Get our requested location
# ( 0 = node itself, 1 = this file, 2 = first argument)
if process.argv[2]?
    root = path.resolve process.cwd(), process.argv[2]
    fs.access root, fs.constants.F_OK, (err)->
      if err
        console.error err
      else
        compress.main root, (err, msg)->
          if err
            console.error err
          else
            console.log msg


else
  console.log "Please provide a path."
