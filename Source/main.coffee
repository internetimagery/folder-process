# Do the thing

fs = require 'fs'
path = require 'path'
escape_str = require "escape-string-regexp"

IMAGES = [".jpg", ".jpeg", ".png"]
VIDEO = [".mp4", ".mov", ".avi", ".wmv", ".rm", ".3gp", ".mkv", ".scm", ".vid", ".mpeg", ".avchd", ".m2ts"]
BACKUP_DIR = "Originals - Check before deleting" # Where to put original files


compress_video = (src, dest, callback)->
  fs.link src, dest, (err)->
    return callback err if err
    callback null

compress_image = (src, dest, callback)->
  fs.link src, dest, (err)->
    return callback err if err
    callback null


                #
                # # TIME TO MAKE A CHOICE!
                # # Pick the smallest file. Compressing a compressed file can lead to a larger one.
                # size_old = os.stat(media["o_path"]).st_size
                # size_new = os.stat(media["w_path"]).st_size
                #
                # if size_new and size_new < size_old:
                #     # Move our compressed file to the root
                #     shutil.move(media["w_path"], media["n_path"])
                # else:
                #     # Otherwise we didn't really accomplish much. Discard compressed file.
                #     os.link(media["o_path"], media["n_path"])
                #
                # # Now that we have the compressed file safely complete.
                # # Back up the original file.
                # # If this fails, we will stop. But it's not a big deal as we're not overwriting it.
                # shutil.move(media["o_path"], media["b_path"])
                #
                # # Done! Next file!



# Grab possible files we can use from the root directory
get_candidates = (root, callback)->
  fs.readdir root, (err, files)->
    return callback err if err

    num_start = 0 # Where do we start our file numbering?
    root_name = path.basename(root) # Name of folder
    tag_convention = /\[.+?\]/
    naming_convention = new RegExp escape_str(root_name) + "_(\\d+)"
    candidates = []

    # Look through file and grab files that don't match the naming convention
    # for media in (f f/or f in scandir(root) if f.is_file(follow_symlinks=False)):
    for m_name in files
        m_path = path.join root, m_name
        if fs.lstatSync(m_path).isFile()
          check = naming_convention.exec m_name # Check the file matches convention

          # If we have a file that matches the naming convention
          # then take the digit of the file as out new starting point.
          # We assume that a file matching naming conventions has already
          # been processed. So we leave it at that.
          if check?
            num_start = Math.max num_start, check[1]

          # We have a file that does not match the naming convention
          # so we assume it needs processing. Add it to our process list.
          else
            candidates.push {
              "o_name" : m_name
              "o_path" : m_path
            }

      # Figure out the number of zeros (padding) to use for Numbering
      num_zeroes = (num_start + candidates.length).toString().length
      if num_zeroes < 3
        num_zeroes = 3

      # Assemble a new name for each file
      for media in candidates
        num_start += 1

        num_str = num_start.toString()
        num_str = "0".repeat(num_zeroes - num_str.length) + num_str

        check = tag_convention.exec media.o_name
        tags = if check? then check[0] else ""

        ext = path.extname(media.o_name).toLowerCase()
        if ext in IMAGES
          media.type = 1
        else if ext in VIDEO
          media.type = 2
          ext = ".mp4" # Converting to mp4
        else
          media.type = 0

        media.n_name = "#{root_name}_#{num_str}#{tags}#{ext}"
        media.n_path = path.join root, media.n_name

      callback null, candidates


# Lets do it!
this.main = (root, callback)->

  # Check we have read write permission first
  fs.access root, fs.constants.R_OK | fs.constants.W_OK, (err)->
    return callback err if err
    get_candidates root, (err, candidates)->
      return callback err if err


      if candidates

        b_dir = path.join root, BACKUP_DIR

        # Check there are no files already in place
        # Even though other files could pop up later,
        # This early check enables us to stop before doing
        # expensive compressing early.
        i = candidates.length
        candidates.forEach (media)->
          media.b_path = path.join b_dir, media.o_name

          fs.access media.n_path, (err)-> # Check we have nothing in backup already
            return callback new Error "File exists. Please fix and try again. #{media.n_path}" if not err? or err.code != "ENOENT"

            fs.access media.b_path, (err)-> # Check we have nothing in backup already
              return callback new Error "File exists. Please fix and try again. #{media.o_path}" if not err? or err.code != "ENOENT"

              i -= 1
              if i == 0 # We are ok to continue, no errors.

                # Create backup directory
                fs.mkdir b_dir, (err)->
                  return callback err if err? and err.code != "EEXIST"

                  candidates.forEach (media)->

                    # Work out which compression type to use.
                    # Compress into temporary working directory.
                    # For unknown file type, simply link to working directory.
                    compress_func = null
                    console.log "Compressing: #{media.o_name} => #{media.n_name}"
                    switch media.type
                      when 1 then compress_func = compress_image
                      when 2 then compress_func = compress_video
                      else compress_func = fs.link

                    compress_func media.o_path, media.n_path, (err)->
                      fs.stat media.o_path, (err, o_stat)->
                        return callback err if err
                        fs.stat media.n_path, (err, n_stat)->
                          return callback err if err

                          # Compare the two sizes. If the compression did NOT shrink
                          # the file. Then just keep the original.
                          if n_stat.size < o_stat.size
                            fs.link media.o_path, media.b_path, (err)->
                              return callback err if err
                              fs.unlink media.o_path, (err)->
                                return callback err if err
                                console.log "Compression complete: #{media.o_name}"
                                callback null, media
                          else
                            fs.unlink media.n_path, (err)->
                              return callback err if err
                              fs.link media.o_path, media.n_path, (err)->
                                return callback err if err
                                fs.link media.o_path, media.b_path, (err)->
                                  return callback err if err
                                  fs.unlink media.o_path, (err)->
                                    return callback err if err
                                    console.log "Compression unneeded: #{media.o_name}"
                                    callback null, media
                          # DONE!













                  console.log "ok"
