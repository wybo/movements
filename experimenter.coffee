code = require "./model_headless.coffee"
MM = code.MM
abmCode = require "./lib/agentbase.coffee"
ABM = abmCode.ABM
u = ABM.util
argv = require('yargs').argv
childProcess = require('child_process')
os = require('os')
fs = require('fs')

# ### Running experiments

runFork = ->
  process.on('message', (message) ->
    if message == "done"
      process.disconnect()
    else
      printSetup(message)
      process.send(runTest(message))
  )

runExperiment = (experiment, nrOfChildren = false) ->
  console.log "# Running experiments"
  if nrOfChildren
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

runTest = (testSetup, callback = null) ->
  config = getConfig(testSetup)
  model = MM.Initializer.initialize(config)
  model = runModel(model)
  config.config = null # removing circularity
  testSetup.config = config # full config
  output = experimentSetupNr: testSetup.experimentSetupNr, testSetup: testSetup, data: model.data
  if callback
    callback(null, output)
  else
    return output

outputExperiment = (tests) ->
  output = []
  tests.sort("experimentSetupNr")
  lastExperimentSetupNr = tests[0].experimentSetupNr
  lastTestSetup = tests[0].testSetup
  runs = []

  for test in tests
    if test.experimentSetupNr != lastExperimentSetupNr # Next group of runs
      output.push {setup: lastTestSetup, fullData: runs}
      lastExperimentSetupNr = test.experimentSetupNr
      lastTestSetup = test.testSetup
      runs = []

    runs.push test.data

  output.push {setup: lastTestSetup, fullData: runs}

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
    if key == "media"
      config[key] = ABM.Array.from value
    else
      config[key] = value

  config.check()
  config.setFunctions() # IMPORTANT!

  return config

jsonConfig = ->
  config = new MM.Config
  config.makeHeadless()
  config.config = null
  console.log JSON.stringify(config, null)

printSetup = (setup) ->
  console.log "# eSetupNr: " + setup.experimentSetupNr + ", reruns: " + setup.experimentReruns + ", label " + setup.label

readExperiment = (experimentFile) ->
  experiment = JSON.parse(fs.readFileSync(experimentFile, 'utf8'))

if argv.json == "config"
  jsonConfig()
else if process.env.FORK
  runFork()
else if argv.experiment
  experiment = readExperiment(argv.experiment)
    
  if argv.mode == "single"
    runExperiment(experiment)
  else
    runExperiment(experiment, os.cpus().length)
else
  throw "provide --experiment=setups/setup-file.json, setup file"
