code = require "./model_headless.coffee"
MM = code.MM
abmcode = require "./lib/agentbase.coffee"
ABM = abmcode.ABM
u = ABM.util

experimentReruns = 3
#reruns = 10
#reruns = 30
#reruns = 25 # To average it out

#generations = 2
experimentGenerations = 150
#generations = 300
#generations = 1500
#generations = 150 # 15 days

mediaSetups = [
  {label: "Forum", experimentMedia: [[50, "forum"], [100, "email"]]}
]

setups = [
  {friends: MM.FRIENDS.random, friendsHardshipHomophilous: false, label: "friends random, not homophilous"}
#  {friends: MM.FRIENDS.random, friendsHardshipHomophilous: true, label: "friends random, homophilous"}
#  {friends: MM.FRIENDS.local, friendsHardshipHomophilous: false, label: "friends local, not homophilous"}
#  {friends: MM.FRIENDS.local, friendsHardshipHomophilous: true, label: "friends local, homophilous"}
]
#setupSets = [
#  {mediumCountsFor: 0.05, label: "medium counts for little"}
#  {mediumCountsFor: 0.20, label: "medium counts for some"}
#  {mediumCountsFor: 0.50, label: "medium counts for a lot"}
#]

runExperiment = (experiment) ->
  output = []

  for testSetup in experiment
    output.push runTest(testSetup)

  console.log JSON.stringify(output, null)

runTest = (testSetup) ->
  runs = []
  config = null

  for [1..testSetup.experimentReruns]
    config = getConfig(testSetup)
    model = MM.Initializer.initialize(config)
    model = runModel(model)
    runs.push(model.data)

  runs = averageRuns(runs)

  config.config = null # removing circularity
  testSetup.config = config # full config
  return {setup: testSetup, data: runs[0]}

runModel = (model) ->
  mediaIndex = 0
  for [1..model.config.experimentGenerations]
    model.once()
    if model.config.experimentMedia and mediaIndex < model.config.experimentMedia.length and model.animator.ticks == model.config.experimentMedia[mediaIndex][0]
      medium = model.config.experimentMedia[mediaIndex][1]
      model.config.medium = MM.MEDIA[medium]
      model.media.changed()
      mediaIndex += 1

  return model

getConfig = (testSetup) ->
  config = new MM.Config

  if config.testRun
    throw "Cannot be a testRun if headless."
  config.makeHeadless()

  for own key, value of testSetup
    config[key] = value

  return config

averageRuns = (runs) ->
  for run, i in runs
    if i > 0
      for key, variable of run
        if key != "media"
          for pair, k in variable
            runs[0][key][k][1] += pair[1] * 1.0

  for key, variable of runs[0]
    if key != "media"
      for pair, k in variable
        runs[0][key][k][1] = Math.round(runs[0][key][k][1] / runs.length * 100) / 100
  
  return runs

prepareExperiment = (setups, mediaSetups, experimentGenerations, experimentReruns) ->
  experiment = []

  for setup in setups
    setup.experimentGenerations = experimentGenerations
    setup.experimentReruns = experimentReruns

    for mediaSetup in mediaSetups
      newLabel = mediaSetup.label + " " + setup.label
      if mediaSetup.experimentMedia
        if mediaSetup.experimentMedia[0][0] == 0
          mediaSetup.medium = MM.MEDIA[mediaSetup.experimentMedia[0][0][1]]
        else
          mediaSetup.medium = MM.MEDIA.none

      else if mediaSetup.medium and u.isString(mediaSetup.medium)
        mediaSetup.medium = MM.MEDIA[mediaSetup.medium]

      experiment.push u.merge(u.merge(mediaSetup, setup), {label: newLabel})

  return experiment

experiment = prepareExperiment(setups, mediaSetups, experimentGenerations, experimentReruns)

runExperiment(experiment)
