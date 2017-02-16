
gulp = require 'gulp'
coffee = require 'gulp-coffee'

# Move webpages to public folder
gulp.task "html", ->
  gulp.src "src/*.html"
  .pipe gulp.dest "public/"

# Move images to public
gulp.task "img", ->
  gulp.src "src/img/*"
  .pipe gulp.dest "public/img/"

# Move javascript to public
gulp.task "js", ->
  gulp.src "src/js/*.coffee"
  .pipe coffee()
  .pipe gulp.dest "public/js/"

# Move css to public
gulp.task "css", ->
  gulp.src "src/css/*.css"
  .pipe gulp.dest "public/css/"

# Move vendor stuff to public
gulp.task "vendor", ->
  gulp.src "src/vendor/**/*"
  .pipe gulp.dest "public/vendor/"

gulp.task "build", ["html", "css", "js", "img", "vendor"], ->
  console.log "webpage built"
