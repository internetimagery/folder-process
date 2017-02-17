# Manage our naming convention!

fs = require './fs'
path = require 'path'
escape_str = require "escape-string-regexp"


# Some conventions
TAGS = /\[.+?\]/
NAMING = (dir)-> new RegExp escape_str(dir) + "_(\\d+)"

# Collect files that match our naming and grab the largest index
match = (dir)->
  results =
    dir: path.basename dir
    ok: [] # Files that match our convention
    fail: [] # Files that failed to match the convention
    index: 0 # The highest index of our convention files
  convention = NAMING results.dir
  fs.readdir dir
  .then (files)->
    return results if not files.length
    Promise.all (fs.stat path.join dir, f for f in files)
    .then (stats)->
      for f, i in files
        if stats[i].isFile()
          match = convention.exec f
          if match
            results.index = Math.max results.index, parseInt match[1]
            results.ok.push f
          else
            results.fail.push f
      results

# Rename files to match convention
rename = (dir, files, index)->
  result = []

  # How much padding is needed?
  pad = Math.max 3, (index + files.length).toString().length

  for f in files
    index += 1
    index_str = index.toString()
    index_str = "0".repeat(pad - index_str.length) + index_str

    tags = TAGS.exec f
    tags = if tags? then tags[0] else ""

    ext = path.extname f
          .toLowerCase()

    result.push {
      src: f
      dest: "#{dir}_#{index_str}#{tags}#{ext}"
    }
  result

module.exports = {
  match: match
  rename: rename
}
