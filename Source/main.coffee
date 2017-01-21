# Do the thing

fs = require 'fs'
path = require 'path'


# Grab possible files we can use from the root directory
get_candidates = (root, callback)->
  fs.readdir root, (err, files)->
    if err
      callback err
    else
      callback null, files


# Lets do it!
this.main = (root)->

  # Check we have read write permission first
  fs.access root, fs.constants.R_OK | fs.constants.W_OK, (err)->
    console.error err if err
    get_candidates root, (err, files)->
      console.error err if err
      console.log files
