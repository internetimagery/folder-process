
ffmpeg = require '@ffmpeg-installer/ffmpeg'
path = require 'path'
fs = require './fs'

IMAGE = [".jpg", ".jpeg", ".png"]
VIDEO = [".mp4", ".mov", ".avi", ".wmv", ".rm", ".3gp", ".mkv", ".scm", ".vid", ".mpeg", ".avchd", ".m2ts"]

# Compress an image
cmp_image = (src, dest)->
  fs.ensureLink src, dest

# Compress a video
cmp_video = (src, dest)->
  fs.ensureLink src, dest

# Compress a file!
compress = (src, dest)->
  # Determine file type
  ext = path.extname src
        .toLowerCase()

  func = fs.ensureLink
  if ext in IMAGE
    func = cmp_image
  else if ext in VIDEO
    func = cmp_video
    dest = dest.replace /\.\w+$/, ".mp4" # making file mp4

  func src, dest
  .then ->
    Promise.all [
      fs.stat src
      fs.stat dest
      ]
  .then (stats)->

    # Compare file sizes
    # If the compressed file is larger than the source
    # just remove the compressed one and link the source
    # to the destination>
    if stats[0].size >= stats[1].size
      console.log "Compression Unneeded: #{path.basename src}"
      fs.remove dest
      .then ->
        fs.ensureLink src, dest


module.exports = compress
