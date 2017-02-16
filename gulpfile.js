(function() {
  var coffee, gulp;

  gulp = require('gulp');

  coffee = require('gulp-coffee');

  gulp.task("html", function() {
    return gulp.src("src/*.html").pipe(gulp.dest("public/"));
  });

  gulp.task("img", function() {
    return gulp.src("src/img/*").pipe(gulp.dest("public/img/"));
  });

  gulp.task("js", function() {
    return gulp.src("src/js/*.coffee").pipe(coffee()).pipe(gulp.dest("public/js/"));
  });

  gulp.task("css", function() {
    return gulp.src("src/css/*.css").pipe(gulp.dest("public/css/"));
  });

  gulp.task("vendor", function() {
    return gulp.src("src/vendor/**/*").pipe(gulp.dest("public/vendor/"));
  });

  gulp.task("build", ["html", "css", "js", "img", "vendor"], function() {
    return console.log("webpage built");
  });

}).call(this);
