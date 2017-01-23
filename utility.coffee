# Some utility stuff

fs = require 'fs'


# Link a file to another file.
# If the other file exists. Check inode to see if the files are actually the same
this.safe_link = (src, dest, callback)->
  fs.link src, dest, (err)->
    if err
      # If the file already exists, that could be ok. If it's the same file
      if err.code == "EEXIST"
        fs.stat src, (err2, src_stats)->
          return callback err2 if err2
          fs.stat src, (err2, dest_stats)->
            return callback err2 if err2
            # Check if the two files are in fact the same.
            if src_stats.ino == dest_stats.ino
              callback null
            else
              # File exists, but is not the same file, so rethrow the error
              callback err
      else
        callback err
    else
      callback null
