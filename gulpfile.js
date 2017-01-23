(function() {
  var coffee, gulp, jsmin;

  gulp = require('gulp');

  coffee = require("gulp-coffee");

  jsmin = require("gulp-jsmin");

  gulp.task("coffee", function() {
    return gulp.src("./js/*.coffee").pipe(coffee()).pipe(jsmin()).pipe(gulp.dest("./build/js"));
  });

}).call(this);
