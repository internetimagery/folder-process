# Run our server

express = require 'express'
opn = require 'opn'
app = express()

PORT = 3000

app.use express.static "public"

app.get "/*", (req, res)->
  res.send "Hello World"

# app.get "/*", (req, res)->
#   res.send "stuff"

# Start our webserver
server = app.listen PORT, ->
  # Open webbrowser
  opn "http://localhost:#{PORT}"
