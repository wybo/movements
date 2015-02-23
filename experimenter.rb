#!/usr/bin/ruby

experiment = `coffee experimenter.coffee`

experiment = experiment.gsub("\n","")

list = Dir.glob("runs/*")

puts list.inspect

list.reject! {|f| f =~ /experiments/}
list.each {|f| f.gsub!(/runs\//, "")}
list.sort!

new_experiment_file = "experiment." + Time.now.to_i.to_s + ".nr-" +
  (list.size + 1).to_s + ".js"

open("runs/" + new_experiment_file, "w") do |file|
  file.write("experiment = eval('(" + experiment + ")');")
end

list.push(new_experiment_file)

open("runs/experiments.js", "w") do |file|
  file.write("experiments = eval('([\"" + list.join('", "') + "\"])');")
end
