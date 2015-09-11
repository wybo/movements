code = require "./model_headless.coffee"
MM = code.MM

#reruns = 2
reruns = 30
#reruns = 25 # To average it out

#generations = 2
generations = 300
#generations = 150 # 15 days

setups = [
  {label: "None normal", medium: MM.MEDIA.none}
  {label: "Facebook normal", medium: MM.MEDIA.facebook_wall, medium_type: MM.MEDIUM_TYPES.normal}
  {label: "Facebook micro", medium: MM.MEDIA.facebook_wall, medium_type: MM.MEDIUM_TYPES.micro}
  {label: "Facebook uncensored", medium: MM.MEDIA.facebook_wall, medium_type: MM.MEDIUM_TYPES.uncensored}
  {label: "Forum enclave", medium: MM.MEDIA.forum, type: MM.TYPES.enclave}
]

#tests = [
#  {
#    label: "None",
#    medium: MM.MEDIA.none
#  },
#  {
#    label: "Email",
#    medium: MM.MEDIA.email
#  },
#  {
#    label: "Website",
#    medium: MM.MEDIA.website
#  },
#  {
#    label: "Forum",
#    medium: MM.MEDIA.forum
#  }
#]

tests_output = []

run_test = (setup) ->
  # TODO runs
  #
  runs = []

  for [1..reruns]
    config = new MM.Config
    config.makeHeadless()

    for own key, value of setup
      config[key] = value

    model = MM.Initializer.initialize(config)

    for [1..generations]
      model.once()

    runs.push(model.data)

    #return {data: model.data, config: config}

  for run, i in runs
    if i > 0
      for key, variable of run
        for pair, k in variable
          runs[0][key][k][1] += pair[1] * 1.0

  for key, variable of runs[0]
    for pair, k in variable
      runs[0][key][k][1] = Math.round(runs[0][key][k][1] / runs.length * 100) / 100

  config.config = null # removing circularity
  setup.config = config # full config
  return {setup: setup, data: runs[0]}

for setup in setups
  tests_output.push run_test(setup)

console.log JSON.stringify(tests_output, null)

#  hash = forum.data()
#  print(JSON.stringify(hash));
#  if (r < reruns - 1) {
#    print(",");
#  }

#print("[");
#for (var i = 0; i < tests.length; i++) {
#  print("[");
#  experimenter(tests[i]);
#  print("]");
#  if (c_i < tests.length - 1) {
#    print(",");
#  }
#}
#print("]");
