# Manage our naming convention!

fs = require './fs'

#
# # Grab possible files we can use from the root directory
# @get_candidates = (root, callback)->
#   fs.readdir root, (err, files)->
#     return callback err if err
#
#     num_start = 0 # Where do we start our file numbering?
#     root_name = path.basename(root) # Name of folder
#     tag_convention = /\[.+?\]/
#     naming_convention = new RegExp escape_str(root_name) + "_(\\d+)"
#     candidates = []
#
#     # Look through file and grab files that don't match the naming convention
#     # for media in (f f/or f in scandir(root) if f.is_file(follow_symlinks=False)):
#     for m_name in files
#         m_path = path.join root, m_name
#         if fs.lstatSync(m_path).isFile()
#           check = naming_convention.exec m_name # Check the file matches convention
#
#           # If we have a file that matches the naming convention
#           # then take the digit of the file as out new starting point.
#           # We assume that a file matching naming conventions has already
#           # been processed. So we leave it at that.
#           if check?
#             num_start = Math.max num_start, check[1]
#
#           # We have a file that does not match the naming convention
#           # so we assume it needs processing. Add it to our process list.
#           else
#             candidates.push {
#               "o_name" : m_name
#               "o_path" : m_path
#             }
#
#       # Figure out the number of zeros (padding) to use for Numbering
#       num_zeroes = (num_start + candidates.length).toString().length
#       if num_zeroes < 3
#         num_zeroes = 3
#
#       # Assemble a new name for each file
#       for media in candidates
#         num_start += 1
#
#         num_str = num_start.toString()
#         num_str = "0".repeat(num_zeroes - num_str.length) + num_str
#
#         check = tag_convention.exec media.o_name
#         tags = if check? then check[0] else ""
#
#         ext = path.extname(media.o_name).toLowerCase()
#         if ext in IMAGES
#           media.type = 1
#         else if ext in VIDEO
#           media.type = 2
#           ext = ".mp4" # Converting to mp4
#         else
#           media.type = 0
#
#         media.n_name = "#{root_name}_#{num_str}#{tags}#{ext}"
#         media.n_path = path.join root, media.n_name
#
#       callback null, candidates
