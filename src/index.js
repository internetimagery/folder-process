(function() {
  var app, createMainWindow, electron, onClosed;

  electron = require("electron");

  app = electron.app;

  this.mainWindow = null;

  onClosed = (function(_this) {
    return function() {
      return _this.mainWindow = null;
    };
  })(this);

  createMainWindow = (function(_this) {
    return function() {
      var win;
      win = new electron.BrowserWindow({
        width: 600,
        height: 400
      });
      win.loadURL("file://" + __dirname + "/index.html");
      win.on("closed", onClosed);
      return win;
    };
  })(this);

  app.on("window-all-closed", (function(_this) {
    return function() {
      if (process.platform !== "darwin") {
        return app.quit();
      }
    };
  })(this));

  app.on("activate", (function(_this) {
    return function() {
      if (!_this.mainWindow) {
        return _this.mainWindow = createMainWindow();
      }
    };
  })(this));

  app.on("ready", (function(_this) {
    return function() {
      return _this.mainWindow = createMainWindow();
    };
  })(this));

}).call(this);
