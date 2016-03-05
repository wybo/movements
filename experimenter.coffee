code = require "./model_headless.coffee"
MM = code.MM
abmcode = require "./lib/agentbase.coffee"
ABM = abmcode.ABM
u = ABM.util

experimentReruns = 2
#reruns = 10
#reruns = 30
#reruns = 25 # To average it out

#experimentTicks = 2
experimentTicks = 15
#experimentTicks = 300
#experimentTicks = 1500
#experimentTicks = 150 # 15 days

mediaSetups = null
mediaSetups = [
  {label: "Forum", experimentChange: {tick: 5, medium: "forum"}}
  {label: "Email", medium: "email"}
]

setups = [
  {
    label: "Epstein basic", type: "normal", legitimacyCalculation: "base",
    experimentChanges: [{tick: 5, medium: "forum"}, {tick: 10, medium: "tv"}]
  }
#  {friends: MM.FRIENDS.random, friendsHardshipHomophilous: true, label: "friends random, homophilous"}
#  {friends: MM.FRIENDS.local, friendsHardshipHomophilous: false, label: "friends local, not homophilous"}
#  {friends: MM.FRIENDS.local, friendsHardshipHomophilous: true, label: "friends local, homophilous"}
]
#setupSets = [
#  {mediumCountsFor: 0.05, label: "medium counts for little"}
#  {mediumCountsFor: 0.20, label: "medium counts for some"}
#  {mediumCountsFor: 0.50, label: "medium counts for a lot"}
#]

# ### Running experiments

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
  changesIndex = 0
  for [1..model.config.experimentTicks]
    model.once()
    if model.config.experimentChanges and changesIndex < model.config.experimentChanges.length and
        model.animator.ticks == model.config.experimentChanges[changesIndex].tick
      for key, value of model.config.experimentChanges[changesIndex]
        if key != "tick"
          model.set(key, value)
      changesIndex += 1

  return model

getConfig = (testSetup = {}) ->
  config = new MM.Config
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

# ### Preparation of runs

prepareExperiment = (setups, experimentTicks, experimentReruns, mediaSetups = null) ->
  if mediaSetups
    newSetups = []

    for setup in setups
      for mediaSetup in mediaSetups
        newLabel = mediaSetup.label + " " + setup.label
        newSetups.push u.merge(u.merge(mediaSetup, setup), {label: newLabel})

    setups = newSetups

  config = getConfig()

  for setup in setups
    if setup.experimentChange
      setup.experimentChanges = [setup.experimentChange]
      delete setup.experimentChange

    setup.experimentTicks ?= experimentTicks
    setup.experimentReruns ?= experimentReruns
    setup.medium ?= MM.MEDIA.none
    for key, value of config.hashes
      if setup[key]
        setup[key] = replaceConfigString(setup[key], value)

    if setup.experimentChanges
      setup.experimentChanges.sort("tick")
      for changes in setup.experimentChanges
        for key, value of config.hashes
          if changes[key]
            changes[key] = replaceConfigString(changes[key], value)

  return setups

replaceConfigString = (string, hash) ->
  if string and u.isString(string)
    return hash[string]
  else
    return string

experiment = prepareExperiment(setups, experimentTicks, experimentReruns, mediaSetups)

runExperiment(experiment)
