# Lets make a build process!

gulp = require 'gulp'
coffee = require "gulp-coffee"
jsmin = require "gulp-jsmin"

gulp.task "coffee", ()->
  gulp.src "./js/*.coffee"
  .pipe coffee()
  .pipe jsmin()
  .pipe gulp.dest "./build/js"
