code = require "./model_headless.coffee"
MM = code.MM
abmCode = require "./lib/agentbase.coffee"
ABM = abmCode.ABM
u = ABM.util
argv = require('yargs').argv
childProcess = require('child_process')
os = require('os')

experimentReruns = 1
#experimentReruns = 10
#experimentReruns = 30
#experimentReruns = 25 # To average it out

#experimentTicks = 2
experimentTicks = 200
#experimentTicks = 250
#experimentTicks = 300
#experimentTicks = 1000
#experimentTicks = 1500
#experimentTicks = 150 # 15 days

mediaSetups = null
#mediaSetups = [
#  {label: "Forum", experimentChange: {tick: 5, medium: "forum"}}
#  {label: "Email", medium: "email"}
#]
mediaSetups = [
  {label: "1, 0.72", experimentReruns: 1, baseRegimeLegitimacy: 0.72}
  {label: "30, 0.72", experimentReruns: 30, baseRegimeLegitimacy: 0.72}
  {label: "1, 0.74", experimentReruns: 1, baseRegimeLegitimacy: 0.74}
  {label: "30, 0.74", experimentReruns: 30, baseRegimeLegitimacy: 0.74}
  {label: "1, 0.76", experimentReruns: 1, baseRegimeLegitimacy: 0.76}
  {label: "30, 0.76", experimentReruns: 30, baseRegimeLegitimacy: 0.76}
]

setups = [
  {
    label: "Epstein basic", type: "normal", calculation: "epstein", legitimacyCalculation: "base", friends: "none", medium: "none"
  },
  {
    label: "Real arrest probability", type: "normal", calculation: "real", legitimacyCalculation: "base", friends: "none", medium: "none"
  },
  {
    label: "With square", type: "square", calculation: "real", legitimacyCalculation: "base", friends: "none", medium: "none"
  },
  {
    label: "With friends", type: "square", calculation: "real", legitimacyCalculation: "base", friends: "random", medium: "none"
  },
  {
    label: "With prison-capacity to 40% of agents", type: "normal", calculation: "real", legitimacyCalculation: "base", friends: "none", medium: "none", prisonCapacity: 0.4
  },
  {
    label: "With defecting cops", type: "normal", calculation: "real", legitimacyCalculation: "base", friends: "none", medium: "none", copsDefect: true
  },
  {
    label: "With legitimacy affected by arrests", type: "normal", calculation: "real", legitimacyCalculation: "arrests", friends: "none", medium: "none", copsDefect: true
  },
  # Forum and other media
  {
    label: "With a medium; tv, total censorship", type: "normal", calculation: "real", legitimacyCalculation: "arrests", friends: "random", medium: "tv", mediumType: "totalCensorship", copsDefect: true
  },
  {
    label: "With a medium; tv, normal censorship", type: "normal", calculation: "real", legitimacyCalculation: "arrests", friends: "random", medium: "tv", copsDefect: true
  },
  {
    label: "With a medium; forum", type: "normal", calculation: "real", legitimacyCalculation: "arrests", friends: "random", medium: "forum", mediumType: "uncensored", copsDefect: true
  },
  {
    label: "With a medium; forum, censored", type: "normal", calculation: "real", legitimacyCalculation: "arrests", friends: "random", medium: "forum", mediumType: "censored", copsDefect: true
  },
  {
    label: "With a medium; facebook", type: "normal", calculation: "real", legitimacyCalculation: "arrests", friends: "random", medium: "facebookWall", mediumType: "uncensored", copsDefect: true
  },
  # Mechanisms
    #{
    #  label: "Forum with seclusion", type: "normal", calculation: "real", legitimacyCalculation: "arrests", friends: "random", medium: "forum", mediumType: "uncensored", copsDefect: true
    #},
    #{
    #  label: "Facebook with seclusion", type: "normal", calculation: "real", legitimacyCalculation: "arrests", friends: "random", medium: "tv", mediumType: "uncensored", copsDefect: true
    #},
  {
    label: "With exposition to friends", type: "normal", calculation: "real", legitimacyCalculation: "arrests", friends: "random", medium: "none", copsDefect: true
  },
  {
    label: "Facebook with exposition", type: "normal", calculation: "real", legitimacyCalculation: "arrests", friends: "random", medium: "facebookWall", mediumType: "uncensored", copsDefect: true
  },
  {
    label: "Facebook with micro", type: "normal", calculation: "real", legitimacyCalculation: "arrests", friends: "random", medium: "facebookWall", mediumType: "micro", copsDefect: true
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

runTest = (testSetup, callback = null) ->
  config = getConfig(testSetup)
  model = MM.Initializer.initialize(config)
  model = runModel(model)
  config.config = null # removing circularity
  testSetup.config = config # full config
  output = setupNr: testSetup.experimentSetupNr, testSetup: testSetup, data: model.data
  if callback
    callback(null, output)
  else
    return output

runExperiment = (experiment, nrOfChildren = false) ->
  if process.env.FORK
    process.on('message', (message) ->
      if message == "done"
        process.disconnect()
      else
        process.send(runTest(message))
    )
  else if nrOfChildren
    tests = new ABM.Array
    nrOfChildren = os.cpus().length
    done = 0

    for i in [0...nrOfChildren]
      child = childProcess.fork('./experimenter.coffee', env: {FORK: true})

      child.on('message', ((child, message) ->
        tests.push message
        if experiment.length > 0
          child.send(experiment.pop())
        else
          child.send("done")
          done += 1
          if done == nrOfChildren
            outputExperiment(tests)
      ).bind(undefined, child))

      child.send(experiment.pop())
  else
    tests = new ABM.Array
    for testSetup in experiment
      testOutput = runTest(testSetup)
      tests.push(testOutput)

    outputExperiment(tests)

outputExperiment = (tests) ->
  output = []
  tests.sort("setupNr")
  lastSetupNr = tests[0].setupNr
  lastTestSetup = tests[0].testSetup
  runs = []

  for test in tests
    if test.setupNr != lastSetupNr
      runs = averageRuns(runs)
      output.push {setup: lastTestSetup, data: runs[0]}
      lastSetupNr = test.setupNr
      lastTestSetup = test.testSetup
      runs = []

    runs.push test.data

  runs = averageRuns(runs) # for last setupNr
  output.push {setup: lastTestSetup, data: runs[0]}

  console.log JSON.stringify(output, null)

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
    if !key.match(/^(experiment.*|label)$/) and !config.hasOwnProperty(key)
      throw "Property #{key} is not a valid setting"
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
  expandedSetups = []

  setups = prepareSetups(setups, experimentTicks, experimentReruns, mediaSetups)
  setupNr = 0
  for setup in setups
    for [1..setup.experimentReruns]
      expandedSetups.push u.merge setup, {experimentSetupNr: setupNr}
    setupNr += 1

  return expandedSetups

prepareSetups = (setups, experimentTicks, experimentReruns, mediaSetups) ->
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
    integer = hash[string]
    if !u.isInteger(integer)
      throw "No setting for string #{string}, typo?"
    return integer
  else
    return string

experiment = prepareExperiment(setups, experimentTicks, experimentReruns, mediaSetups)
console.log experiment
if argv.mode == "single"
  runExperiment(experiment)
else
  runExperiment(experiment, os.cpus().length)
