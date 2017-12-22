#!/usr/bin/ruby

require 'json'
require 'descriptive_statistics'

list = Dir.glob("experiments/*")

list.reject! {|f| f =~ /experiments.js/}
list_len = list.length
list.reject! {|f| list.include?(f + ".back") }
list.reject! {|f| f =~ /\.js\.back$/ }
list.each {|f| f.gsub!(/experiments\//, "")}
list.sort!

if list_len != list.length
  puts "# ONLY Did"
else
  puts "# Did"
end
puts list.inspect

def backup_experiments(file)
  if !File.exists?("experiments/#{file}.back")
    `cp experiments/#{file} experiments/#{file}.back`
  end
end

def read_experiments(file)
  string = File.read("experiments/#{file}")
  string.gsub!(/^experiment = eval\(\'\(/, "")
  string.gsub!(/\)\'\);$/, "")
  experiment_array = JSON.parse(string)
  return experiment_array
end

def write_experiment(file, experiment_array)
  open("experiments/#{file}", "w") do |file|
    file.write("experiment = eval('(" + JSON.generate(experiment_array) + ")');")
  end
end

def get_peaks(series)
  peaks = []
  band = 3
  middle = 3
  pre = []
  current = []
  post = []
  sum = []
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
    sum << pair[1]
  end
  cut_off = sum.mean + sum.standard_deviation * 1.5
  peaks.uniq!
  peaks.select! {|p| p[1] > cut_off}
  return peaks
end

def get_overthrow(series)
  last = 0
  series.each do |pair|
    if pair[1] == 0
      return pair[0]
    end
    last = pair[0]
  end
  return last
end

def unzip_ticks(series)
  ticks = []
  series.each do |couple|
    ticks << couple[0]
  end
  return ticks
end

def collect_all(series, all)
  series.each_with_index do |couple, index|
    if !all[index]
      all[index] = [couple[1]]
    else
      all[index] << couple[1]
    end
  end
  return all
end

def average(all)
  averages = []
  all.each do |array|
    averages << array.mean
  end
  return averages
end

def standard_deviate(all)
  stddevs = []
  all.each do |array|
    stddevs << array.standard_deviation
  end
  return stddevs
end

def interval(averages, stddevs)
  top_intervals = []
  bottom_intervals = []
  averages.each_with_index do |average, index|
    top_intervals << average + stddevs[index] * 1.96
    bottom_intervals << average - stddevs[index] * 1.96
  end
  return [top_intervals, bottom_intervals]
end

def process_experiment(hash)
  ticks = nil
  media = nil

  all_passives = []
  all_actives = []
  all_micros = []
  all_arrests = []
  all_prisoners = []
  all_cops = []
  all_onlines = []
  all_media = []

  all_peaks = []
  all_peaks_per_tick = []
  all_overthrows = []
  hash["fullData"].each do |run|
    ticks ||= unzip_ticks(run["actives"])
    media ||= run["media"]
    all_passives = collect_all(run["passives"], all_passives)
    all_actives = collect_all(run["actives"], all_actives)
    all_micros = collect_all(run["micros"], all_micros)
    all_arrests = collect_all(run["arrests"], all_arrests)
    all_prisoners = collect_all(run["prisoners"], all_prisoners)
    all_cops = collect_all(run["cops"], all_cops)
    all_onlines = collect_all(run["onlines"], all_onlines)

    run["peaks"] = get_peaks(run["actives"])
    all_peaks << run["peaks"].length
    run["peaksPerTick"] = (1.0 * run["peaks"].length / run["actives"].length).round(3)
    all_peaks_per_tick << run["peaksPerTick"]
    run["overthrow"] = get_overthrow(run["cops"])
    all_overthrows << run["overthrow"]
  end
  hash["data"] ||= {}
  hash["data"]["passives"] = ticks.zip(average(all_passives))
  hash["data"]["actives"] = ticks.zip(average(all_actives))
  hash["data"]["micros"] = ticks.zip(average(all_micros))
  hash["data"]["arrests"] = ticks.zip(average(all_arrests))
  hash["data"]["prisoners"] = ticks.zip(average(all_prisoners))
  hash["data"]["cops"] = ticks.zip(average(all_cops))
  hash["data"]["onlines"] = ticks.zip(average(all_onlines))
  hash["data"]["media"] = media

  actives_t95, actives_b95 = interval(average(all_actives), standard_deviate(all_actives))
  hash["data"]["actives_t"] = ticks.zip(actives_t95)
  hash["data"]["actives_b"] = ticks.zip(actives_b95)
  cops_t95, cops_b95 = interval(average(all_cops), standard_deviate(all_cops))
  hash["data"]["cops_t"] = ticks.zip(cops_t95)
  hash["data"]["cops_b"] = ticks.zip(cops_b95)
  prisoners_t95, prisoners_b95 = interval(average(all_prisoners), standard_deviate(all_prisoners))
  hash["data"]["prisoners_t"] = ticks.zip(prisoners_t95)
  hash["data"]["prisoners_b"] = ticks.zip(prisoners_b95)

  hash["stats"] ||= {}
  hash["stats"]["avg_peaks"] = all_peaks.mean
  hash["stats"]["avg_peaksPerTick"] = all_peaks_per_tick.mean
  hash["stats"]["avg_overthrow"] = all_overthrows.mean
  nr_of_overthrows = all_overthrows.select {|o| o < ticks.last}.length * 1.0
  hash["stats"]["perc_overthrow"] = nr_of_overthrows / hash["fullData"].length
  #hash["fullData"] = nil
  return hash
end

list.each do |file|
  backup_experiments(file)
  experiment_array = read_experiments(file)
  experiment_array.each do |hash|
    if hash["fullData"]
      process_experiment(hash)
    end
  end
  write_experiment(file, experiment_array)
end

