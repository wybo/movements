code = require "./model_headless.coffee"
MM = code.MM
abmCode = require "./lib/agentbase.coffee"
ABM = abmCode.ABM
u = ABM.util
argv = require('yargs').argv
childProcess = require('child_process')
os = require('os')

#experimentReruns = 2
#experimentReruns = 10
experimentReruns = 30
#experimentReruns = 25 # To average it out

#experimentTicks = 2
#experimentTicks = 15
#experimentTicks = 200
experimentTicks = 250
#experimentTicks = 300
#experimentTicks = 1000
#experimentTicks = 1500
#experimentTicks = 150 # 15 days

mediaSetups = null
#mediaSetups = [
#  {label: "Forum", experimentChange: {tick: 5, medium: "forum"}}
#  {label: "Email", medium: "email"}
#  {label: "Email, TV", media: ["email", "tv"]}
#]
mediaSetups = [
  {label: "1, 0.65", experimentReruns: 1, baseRegimeLegitimacy: 0.65}
  {label: "30, 0.65", experimentReruns: 30, baseRegimeLegitimacy: 0.65}
  {label: "1, 0.68", experimentReruns: 1, baseRegimeLegitimacy: 0.68}
  {label: "30, 0.68", experimentReruns: 30, baseRegimeLegitimacy: 0.68}
  {label: "1, 0.70", experimentReruns: 1, baseRegimeLegitimacy: 0.70}
  {label: "30, 0.70", experimentReruns: 30, baseRegimeLegitimacy: 0.70}
  {label: "1, 0.72", experimentReruns: 1, baseRegimeLegitimacy: 0.72}
  {label: "30, 0.72", experimentReruns: 30, baseRegimeLegitimacy: 0.72}
  {label: "1, 0.74", experimentReruns: 1, baseRegimeLegitimacy: 0.74}
  {label: "30, 0.74", experimentReruns: 30, baseRegimeLegitimacy: 0.74}
]

#mediaSetups = [
#  {label: "1, 0.65", experimentReruns: 2, baseRegimeLegitimacy: 0.65}
#]

setups = [
  {
    label: "Epstein basic", type: "normal", calculation: "epstein", legitimacyCalculation: "base", friends: "none", medium: "none"
  },
  {
    label: "Real arrest probability", type: "normal", calculation: "real", legitimacyCalculation: "base", friends: "none", medium: "none"
  },
  {
    label: "Square", type: "square", calculation: "real", legitimacyCalculation: "base", friends: "none", medium: "none"
  },
  {
    label: "Friends", type: "square", calculation: "real", legitimacyCalculation: "base", friends: "random", medium: "none"
  },
  {
    label: "Prison-capacity to 40% of agents", type: "normal", calculation: "real", legitimacyCalculation: "base", friends: "none", medium: "none", prisonCapacity: 0.4
  },
  {
    label: "Defecting cops", type: "normal", calculation: "real", legitimacyCalculation: "base", friends: "none", medium: "none", copsDefect: true
  },
  {
    label: "Legitimacy affected by arrests", type: "normal", calculation: "real", legitimacyCalculation: "arrests", friends: "none", medium: "none", copsDefect: true
  },
  # Forum and other media
  {
    label: "Medium; tv, normal censorship", type: "normal", calculation: "real", legitimacyCalculation: "arrests", friends: "random", medium: "tv", mediumType: "normal", copsDefect: true
  },
  {
    label: "Medium; tv, total censorship", type: "normal", calculation: "real", legitimacyCalculation: "arrests", friends: "random", medium: "tv", mediumType: "totalCensorship", copsDefect: true
  },
  {
    label: "Medium; forum", type: "normal", calculation: "real", legitimacyCalculation: "arrests", friends: "random", medium: "forum", mediumType: "normal", copsDefect: true
  },
  {
    label: "Medium; facebook", type: "normal", calculation: "real", legitimacyCalculation: "arrests", friends: "random", medium: "facebookWall", mediumType: "normal", copsDefect: true
  },
  {
    label: "Medium; facebook, uncensored", type: "normal", calculation: "real", legitimacyCalculation: "arrests", friends: "random", medium: "facebookWall", mediumType: "uncensored", copsDefect: true
  },
  # Mechanisms
  {
    label: "Seclusion: TV", type: "normal", calculation: "real", legitimacyCalculation: "arrests", friends: "random", medium: "tv", mediumType: "normal", copsDefect: true, mediaRiskAversionHomophilous: true
  },
  {
    label: "Seclusion: Forum", type: "normal", calculation: "real", legitimacyCalculation: "arrests", friends: "random", medium: "forum", mediumType: "normal", copsDefect: true, mediaRiskAversionHomophilous: true
  },
  {
    label: "Seclusion: Facebook", type: "normal", calculation: "real", legitimacyCalculation: "arrests", friends: "random", medium: "facebookWall", mediumType: "normal", copsDefect: true, friendsRiskAversionHomophilous: true
  },
  {
    label: "Exposition: Forum", type: "normal", calculation: "real", legitimacyCalculation: "arrests", friends: "random", medium: "forum", mediumType: "uncensored", copsDefect: true
  },
  {
    label: "Exposition: Facebook", type: "normal", calculation: "real", legitimacyCalculation: "arrests", friends: "random", medium: "facebookWall", mediumType: "uncensored", copsDefect: true
  },
  {
    label: "Micro: Forum", type: "normal", calculation: "real", legitimacyCalculation: "arrests", friends: "random", medium: "forum", mediumType: "micro", copsDefect: true
  },
  {
    label: "Micro: Facebook", type: "normal", calculation: "real", legitimacyCalculation: "arrests", friends: "random", medium: "facebookWall", mediumType: "micro", copsDefect: true
  }

#  {friends: MM.FRIENDS.random, friendsHardshipHomophilous: true, label: "friends random, homophilous"}
#  {friends: MM.FRIENDS.local, friendsHardshipHomophilous: false, label: "friends local, not homophilous"}
#  {friends: MM.FRIENDS.local, friendsHardshipHomophilous: true, label: "friends local, homophilous"}
]

#setups = [
#  {
#    label: "Real with micro", type: "micro", calculation: "real", legitimacyCalculation: "base", friends: "none", medium: "none"
#  },
#]

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
  console.log "# Running experiments"
  if process.env.FORK
    process.on('message', (message) ->
      if message == "done"
        process.disconnect()
      else
        printSetup(message)
        process.send(runTest(message))
    )
  else if nrOfChildren
    console.log "# (multithreaded)"
    tests = new ABM.Array
    nrOfChildren = os.cpus().length
    done = 0

    if experiment.length < nrOfChildren
      nrOfChildren = experiment.length

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
    console.log "# (single threaded)"
    tests = new ABM.Array
    for testSetup in experiment
      printSetup(testSetup)
      testOutput = runTest(testSetup)
      tests.push(testOutput)

    outputExperiment(tests)

printSetup = (setup) ->
  console.log "# setupNr: " + setup.experimentSetupNr + ", reruns: " + setup.experimentReruns + ", label " + setup.label

outputExperiment = (tests) ->
  output = []
  tests.sort("setupNr")
  lastSetupNr = tests[0].setupNr
  lastTestSetup = tests[0].testSetup
  runs = []

  for test in tests
    if test.setupNr != lastSetupNr # Next group of runs
      averaged = averageRuns(runs)
      output.push {setup: lastTestSetup, data: averaged, fullData: runs}
      lastSetupNr = test.setupNr
      lastTestSetup = test.testSetup
      runs = []

    runs.push test.data

  averaged = averageRuns(runs) # for last setupNr, group of runs
  output.push {setup: lastTestSetup, data: averaged, fullData: runs}

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
  averaged = {}
  for run, i in runs
    for key, variable of run
      averaged[key] ?= []
      if key != "media"
        for pair, k in variable
          averaged[key][k] ?= [pair[0], 0]
          averaged[key][k][1] += pair[1] * 1.0

  for key, variable of averaged
    if key != "media"
      for pair, k in variable
        averaged[key][k][1] = Math.round(averaged[key][k][1] / runs.length * 100) / 100
  
  return averaged

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
    # Expand setting shortcuts
    if setup.medium
      setup.media = new ABM.Array setup.medium
      delete setup.medium

    if setup.experimentChange
      setup.experimentChanges = new ABM.Array setup.experimentChange
      delete setup.experimentChange

    setup.experimentTicks ?= experimentTicks
    setup.experimentReruns ?= experimentReruns

    # Replace hash strings by integers
    if setup.media
      media = setup.media
      setup.media = new ABM.Array
      for medium in media
        setup.media.push replaceConfigString(medium, MM.MEDIA)

    for key, configHash of config.hashes
      if setup[key]
        setup[key] = replaceConfigString(setup[key], configHash)

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

if argv.mode == "single"
  runExperiment(experiment)
else
  runExperiment(experiment, os.cpus().length)
