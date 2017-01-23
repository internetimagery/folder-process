(function() {
  var app, path, window;

  app = require("electron").app;

  path = require("path");

  window = require("electron-window");

  app.on("ready", function() {
    var indexPath, mainWindow;
    app.on("browser-window-created", function(err, win) {
      return win.setMenu(null);
    });
    mainWindow = window.createWindow({
      width: 500,
      height: 600
    });
    indexPath = path.resolve(__dirname, "index.html");
    return mainWindow.showUrl(indexPath, function() {
      console.log("Window up and running!");
      return mainWindow.webContents.openDevTools();
    });
  });

}).call(this);
