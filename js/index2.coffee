# Run the app!

electron = require "electron"
app = electron.app

# Hold reference to keep app running
@mainWindow = null

onClosed = ()=>
  # dereference the window
  @mainWindow = null

createMainWindow = ()=>
  win = new electron.BrowserWindow
    width: 500
    height: 600

  win.loadURL "file://#{__dirname}/index.html"
  win.on "closed", onClosed
  return win

app.on "window-all-closed", ()=>
  app.quit() if process.platform != "darwin"

app.on "activate", ()=>
  @mainWindow = createMainWindow() if !@mainWindow

app.on "ready", ()=>
  # Turn off the default menu
  app.on "browser-window-created", (err, win)->
    win.setMenu null
  @mainWindow = createMainWindow()

  # Open the DevTools.
  @mainWindow.webContents.openDevTools()
