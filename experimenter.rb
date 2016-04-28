#!/usr/bin/ruby

require 'open3'

args = "" # ./experimenter.rb --mode=single for single-threaded
if ARGV.length > 0
  args = " " + ARGV.join(" ")
end
cmd = "./coffee experimenter.coffee#{args}" # TODO fix coffeescript ABM

lines = []
Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
  while line = stdout.gets
    puts line
    if line !~ /^#/
      lines.push line
    end
  end
end

experiment = lines.join(",")
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
