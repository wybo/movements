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

completeFilePaths = (files) ->
  files.map (n) -> 'model/' + n + '.coffee'
  
readFilePaths = (sourceDir, firstFiles, lastFiles, excludeFiles) ->
  firstFiles = completeFilePaths(firstFiles)
  lastFiles = completeFilePaths(lastFiles)
  excludeFiles = completeFilePaths(excludeFiles)

  notNowFiles = firstFiles.concat(lastFiles).concat(excludeFiles)
  fileNames = fs.readdirSync(sourceDir)
    .map (n) -> 'model/' + n
    .filter (file) -> file not in notNowFiles
  firstFiles.concat(fileNames).concat(lastFiles)

uiFiles = ['initializer_head']

FilePaths = readFilePaths 'model/',
  ['config', 'message', 'medium', 'medium_generic_delivery', 'agent_super', 'agent'],
  ['model', 'model_simple', 'initializer'], uiFiles

UIFilePaths = completeFilePaths(uiFiles)

# SpecFilePaths = readFilePaths 'spec/', ['shared.coffee']
 
coffeeTasks = lazypipe()
  .pipe gulp.dest, '' # .coffee files used by specs

gulp.task 'all', ['build', 'docs']

gulp.task 'build', ['build-model']

#gulp.task 'build-model', ['build-model-headless', 'build-model-with']
gulp.task 'build-model', ['build-model-headless', 'build-model-with']

# Build tasks:
gulp.task 'build-model-headless', ->
  return gulp.src(FilePaths)
  .pipe concat('model_headless.coffee')
  .pipe coffeeTasks()

gulp.task 'build-model-with', ["build-model-headless"], ->
  return gulp.src(["model_headless.coffee"].concat(UIFilePaths))
  .pipe concat('model.coffee')
  .pipe coffeeTasks()

#gulp.task 'build-specs', ->
#  return gulp.src(SpecFilePaths)
#  .pipe concat('spec.coffee')
#  .pipe coffeeTasks()

# gulp.task 'build', ['build-model', 'build-specs']

# Watch tasks
# TODO make build as well
gulp.task 'watch', ['build'], ->
  gulp.watch 'model/*.coffee',
    ['build-model']

#  gulp.watch 'spec/*.coffee',
#    ['build-specs']

# Default: list out tasks
gulp.task 'default', taskList
