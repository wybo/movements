code = require "./model_headless.coffee"
MM = code.MM

reruns = 2 # To average it out

generations = 36 # 15 days

note = "Real production data set"

console.log 1
console.log code.TYPES

for [1..reruns]
  console.log 2

  config = new MM.Config
  config.makeHeadless()

  model = MM.Initializer.initialize(config)

  for [1..generations]
    console.log 3
    model.step()

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
