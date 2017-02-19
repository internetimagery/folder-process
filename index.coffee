# Run the app!
electron = require "electron"
path = require "path"
window = require "electron-window"

electron.app.on "ready", ()->
  # Turn off the default menu
  electron.app.on "browser-window-created", (err, win)->
      win.setMenu null
  mainWindow = window.createWindow
    width: 800
    height: 600
    frame: false
  indexPath = path.resolve __dirname, "index.html"


  mainWindow.showUrl indexPath, ()->
    console.log "Window up and running!"
    mainWindow.webContents.openDevTools()
    # mainWindow.setResizable false
