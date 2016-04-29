#!/usr/bin/ruby

require 'json'

list = Dir.glob("experiments/*")

list.reject! {|f| f =~ /experiments.js/}
list.each {|f| f.gsub!(/experiments\//, "")}
list.sort!

def read_experiment(file)
  string = File.read("experiments/" + file)
  string.gsub!(/^experiment = eval\(\'\(\[/, "")
  string.gsub!(/]\)\'\);$/, "")
  hash = JSON.parse(string)
end

def write_experiment(file, hash)
  open("experiments/" + file, "w") do |file|
    file.write("experiment = eval('(" + JSON.generate([hash]) + ")');")
  end
end

def get_peaks(series)
  peaks = []
  band = 3
  middle = 3
  pre = []
  current = []
  post = []
  puts series.inspect
  series.each do |pair|
    post.push pair
    if post.size > band
      current.push post.shift
    end
    if current.size > middle
      pre.push current.shift
    end
    if pre.size > band
      pre.shift
    end
    if pre.size == band
      current_max = current.max {|a,b| a[1] <=> b[1]}
      if pre.max {|a,b| a[1] <=> b[1]}[1] < current_max[1] and post.max {|a,b| a[1] <=> b[1]}[1] < current_max[1]
        peaks.push current_max
      end
    end
  end
  peaks.uniq!
  return peaks
end

def get_overthrow(series)
  series.each do |pair|
    if pair[1] == 0
      return pair[0]
    end
  end
  return nil
end

list.each do |file|
  hash = read_experiment(file)
  hash["fullData"].each do |run|
    run["peaks"] = get_peaks(run["actives"])
    run["peaksPerTick"] = (1.0 * run["peaks"].length / run["actives"].length).round(3)
    run["overthrow"] = get_overthrow(run["cops"])
  end
  puts JSON.pretty_generate(hash)
  write_experiment(file, hash)
end

