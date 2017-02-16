# Run our server

express = require 'express'
opn = require 'opn'
app = express()

PORT = 3000

app.get "/", (req, res)->
  res.send "Hello World"

# Start our webserver
server = app.listen PORT

# Open webbrowser
opn "http://localhost:#{PORT}"
