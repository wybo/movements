# AgentBase is Free Software, available under GPL v3 or any later version.
# Original AgentScript code @ 2013, 2014 Owen Densmore and RedfishGroup LLC.
# AgentBase (c) 2014, Wybo Wiersma.

gulp = require 'gulp'
concat = require 'gulp-concat'
coffee = require 'gulp-coffee'
docco = require 'gulp-docco'
rename = require 'gulp-rename'
shell = require 'gulp-shell'
sourcemaps = require 'gulp-sourcemaps'
uglify = require 'gulp-uglify'
lazypipe = require 'lazypipe'
taskList = require 'gulp-task-listing'
fs = require 'fs'
path = require 'path'

readFilePaths = (sourceDir, firstFiles, lastFiles) ->
  firstFiles = firstFiles.map (n) -> n + '.coffee'
  lastFiles = lastFiles.map (n) -> n + '.coffee'
  notFiles = firstFiles.concat(lastFiles)
  fileNames = fs.readdirSync(sourceDir)
    .filter (file) -> file not in notFiles
  fileNames = firstFiles.concat(fileNames).concat(lastFiles)
  fileNames.map (name) ->
    sourceDir + name

FilePaths = readFilePaths 'model/', ['config', 'medium', 'message'], ['model', 'initializer']

console.log FilePaths

# SpecFilePaths = readFilePaths 'spec/', ['shared.coffee']
 
coffeeTasks = lazypipe()
  .pipe gulp.dest, '' # .coffee files used by specs

gulp.task 'all', ['build', 'docs']

# Build tasks:
gulp.task 'build-model', ->
  return gulp.src(FilePaths)
  .pipe concat('model.coffee')
  .pipe coffeeTasks()

#gulp.task 'build-specs', ->
#  return gulp.src(SpecFilePaths)
#  .pipe concat('spec.coffee')
#  .pipe coffeeTasks()

#gulp.task 'build', ['build-model', 'build-specs']

gulp.task 'build', ['build-model']

# Watch tasks
# TODO make build as well
gulp.task 'watch', ['build'], ->
  gulp.watch 'model/*.coffee',
    ['build-model']

#  gulp.watch 'spec/*.coffee',
#    ['build-specs']

# Default: list out tasks
gulp.task 'default', taskList
