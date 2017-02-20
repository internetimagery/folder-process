(function() {
  var electron, path, window;

  electron = require("electron");

  path = require("path");

  window = require("electron-window");

  electron.app.on("ready", function() {
    var indexPath, mainWindow;
    electron.app.on("browser-window-created", function(err, win) {
      return win.setMenu(null);
    });
    mainWindow = window.createWindow({
      width: 400,
      height: 400,
      frame: false
    });
    indexPath = path.resolve(__dirname, "index.html");
    return mainWindow.showUrl(indexPath, function() {
      console.log("Window up and running!");
      return mainWindow.webContents.openDevTools();
    });
  });

  process.on("exit", function() {
    process.stdout.write("Process Closed");
    this.proc.disconnect();
    return this.proc.kill();
  });

}).call(this);
