# Thin wrapper of fs-extra with promises
fs = require 'fs-extra'
Promise = require 'promise'

module.exports = {}
for k, v of fs
  if typeof v == "function" and not k.endsWith "Sync"
    module.exports[k] = Promise.denodeify v
  else
    module.exports[k] = v
