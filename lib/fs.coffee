# Thin wrapper of fs-extra with promises
fs = require 'fs-extra'
Promise = require 'promise'

module.exports = {}
for k, v of fs
  module.exports[k] = v
  if typeof v == "function"
    if not k.endsWith "Sync"
      if not k.endsWith "Stream"
        module.exports[k] = Promise.denodeify v
