#!/usr/bin/ruby

experiment = `./coffee experimenter.coffee` # TODO fix coffeescript ABM
#experiment = `coffee experimenter.coffee` # TODO fix coffeescript ABM

puts experiment

experiment = experiment.gsub("\n",",")
experiment = experiment.gsub(/],$/,"]")

list = Dir.glob("experiments/*")

list.reject! {|f| f =~ /experiments.js/}
list.each {|f| f.gsub!(/experiments\//, "")}
list.sort!

new_experiment_file = "experiment." + Time.now.to_i.to_s + ".nr-" +
  (list.size + 1).to_s + ".js"

open("experiments/" + new_experiment_file, "w") do |file|
  file.write("experiment = eval('(" + experiment + ")');")
end

list.push(new_experiment_file)

open("experiments/experiments.js", "w") do |file|
  file.write("experiments = eval('([\"" + list.join('", "') + "\"])');")
end
