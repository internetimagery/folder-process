
ffmpeg = require '@ffmpeg-installer/ffmpeg'
path = require 'path'
fs = require './fs'

IMAGE = [".jpg", ".jpeg", ".png"]
VIDEO = [".mp4", ".mov", ".avi", ".wmv", ".rm", ".3gp", ".mkv", ".scm", ".vid", ".mpeg", ".avchd", ".m2ts"]

# Compress a file!
compress = (src, dest)->
  fs.stat src
  .then (stats)->

    # Determine file type
    ext = path.extname src
          .toLowerCase()

    if ext in IMAGE
      console.log "IMAGE"
    else if ext in VIDEO
      console.log "VIDEO"
    else
      console.log "NOTHING"

module.exports = compress
