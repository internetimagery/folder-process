# Process things in a folder

path = require 'path'
fs = require 'fs'
main = require "./main.js"

# Get our requested location
# ( 0 = node itself, 1 = this file, 2 = first argument)
if process.argv[2]?
    root = path.resolve process.cwd(), process.argv[2]
    fs.access root, fs.constants.F_OK, (err)->
      if err
        console.error err
      else
        main.main root, (err)->
          console.error err if err

else
  console.log "Please provide a path."
