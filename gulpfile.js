(function() {
  var coffee, gulp;

  gulp = require('gulp');

  coffee = require('gulp-coffee');

  gulp.task("coffee", function() {
    return gulp.src("**/*.coffee").pipe(coffee()).pipe(gulp.dest("."));
  });

}).call(this);
