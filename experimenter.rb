#!/usr/bin/ruby

require 'open3'
require 'json'

#experimentTicks = 2
#experimentTicks = 15
experimentTicks = 350
#experimentTicks = 350
#experimentTicks = 300
#experimentTicks = 1000
#experimentTicks = 1500
#experimentTicks = 150 # 15 days

#mediaSetups = [
#  {:label => "Forum", experimentChange: {tick: 5, :medium => :forum"}}
#  {:label => "Email", :medium => :email}
#  {:label => "Email, TV", media: [:email, :tv]}
#]

#media_setups = [ # Too low!
#  {:label => "0.58", experimentReruns: 100, baseRegimeLegitimacy: 0.58, arrestDuration: 2, warmupPeriod: 100},
#  {:label => "0.62", experimentReruns: 100, baseRegimeLegitimacy: 0.62, arrestDuration: 2, warmupPeriod: 100},
#  {:label => "0.64", experimentReruns: 100, baseRegimeLegitimacy: 0.64, arrestDuration: 2, warmupPeriod: 100},
#  {:label => "0.66", experimentReruns: 100, baseRegimeLegitimacy: 0.66, arrestDuration: 2, warmupPeriod: 100},
#  {:label => "0.70", experimentReruns: 100, baseRegimeLegitimacy: 0.70, arrestDuration: 2, warmupPeriod: 100}
#]

media_setups = [
  {:label => "0.68", experimentReruns: 100, baseRegimeLegitimacy: 0.68, arrestDuration: 2, warmupPeriod: 100},
  {:label => "0.72", experimentReruns: 100, baseRegimeLegitimacy: 0.72, arrestDuration: 2, warmupPeriod: 100},
  {:label => "0.74", experimentReruns: 100, baseRegimeLegitimacy: 0.74, arrestDuration: 2, warmupPeriod: 100},
  {:label => "0.76", experimentReruns: 100, baseRegimeLegitimacy: 0.76, arrestDuration: 2, warmupPeriod: 100},
  {:label => "0.80", experimentReruns: 100, baseRegimeLegitimacy: 0.80, arrestDuration: 2, warmupPeriod: 100}
]

#media_setups = [
#  {:label => "0.56", experimentReruns: 2, baseRegimeLegitimacy: 0.58, warmupPeriod: 0}
#]

setups = [
  {:label => "Epstein basic",
   :type => :normal, :calculation => :epstein, :legitimacyCalculation => :normal, :friends => :none, :medium => :none},
  {:label => "Real arrest probability",
   :type => :normal, :calculation => :real, :legitimacyCalculation => :normal, :friends => :none, :medium => :none},
  {:label => "Square",
   :type => :square, :calculation => :real, :legitimacyCalculation => :normal, :friends => :none, :medium => :none},
  {:label => "Friends",
   :type => :square, :calculation => :real, :legitimacyCalculation => :normal, :friends => :random, :medium => :none},
  {:label => "Prison-capacity to 20% of agents",
   :type => :normal, :calculation => :real, :legitimacyCalculation => :normal, :friends => :none, :medium => :none, :prisonCapacity => 0.2},
  {:label => "Defecting cops",
   :type => :normal, :calculation => :real, :legitimacyCalculation => :normal, :friends => :none, :medium => :none, :copsDefect => true},
  {:label => "Legitimacy affected by activism",
   :type => :normal, :calculation => :real, :legitimacyCalculation => :activism, :friends => :none, :medium => :none, :copsDefect => false},
 # {:label => "Legitimacy affected by evidence",
 #  :type => :normal, :calculation => :real, :legitimacyCalculation => :evidence, :friends => :none, :medium => :none, :copsDefect => false},
  # Forum and other media
  {:label => "Medium; tv, normal censorship",
   :type => :normal, :calculation => :real, :legitimacyCalculation => :activism, :friends => :random, :medium => :tv, :mediumCensorship => :normal, :copsDefect => true},
  {:label => "Medium; tv, total censorship",
   :type => :normal, :calculation => :real, :legitimacyCalculation => :activism, :friends => :random, :medium => :tv, :mediumCensorship => :totalCensorship, :copsDefect => true},
  {:label => "Medium; forum",
   :type => :normal, :calculation => :real, :legitimacyCalculation => :activism, :friends => :random, :medium => :forum, :mediumCensorship => :normal, :copsDefect => true},
  {:label => "Medium; facebook",
   :type => :normal, :calculation => :real, :legitimacyCalculation => :activism, :friends => :random, :medium => :facebookWall, :mediumCensorship => :normal, :copsDefect => true},
  {:label => "Medium; facebook, uncensored",
   :type => :normal, :calculation => :real, :legitimacyCalculation => :activism, :friends => :random, :medium => :facebookWall, :mediumCensorship => :uncensored, :copsDefect => true},
  # Mechanisms: Secluded Spheres
  {:label => "Seclusion by channels: TV",
   :type => :normal, :calculation => :real, :legitimacyCalculation => :activism, :friends => :random, :medium => :tv, :mediumCensorship => :normal, :mediaRiskAversionHomophilous => true, :copsDefect => true},
  {:label => "Seclusion by channels: Forum",
   :type => :normal, :calculation => :real, :legitimacyCalculation => :activism, :friends => :random, :medium => :forum, :mediumCensorship => :normal, :mediaRiskAversionHomophilous => true, :copsDefect => true},
  {:label => "Seclusion by channels: Facebook",
   :type => :normal, :calculation => :real, :legitimacyCalculation => :activism, :friends => :random, :medium => :facebookWall, :mediumCensorship => :normal, friendsRiskAversionHomophilous: true, :copsDefect => true},
  {:label => "Seclusion media use: TV",
   :type => :normal, :calculation => :real, :legitimacyCalculation => :activism, :friends => :random, :medium => :tv, :mediumCensorship => :normal, :mediaOnlyNonRiskAverseUseMedia => true, :copsDefect => true},
  {:label => "Seclusion media use: Forum",
   :type => :normal, :calculation => :real, :legitimacyCalculation => :activism, :friends => :random, :medium => :forum, :mediumCensorship => :normal, :mediaOnlyNonRiskAverseUseMedia => true, :copsDefect => true},
  {:label => "Seclusion media use: Facebook",
   :type => :normal, :calculation => :real, :legitimacyCalculation => :activism, :friends => :random, :medium => :facebookWall, :mediumCensorship => :normal, :mediaOnlyNonRiskAverseUseMedia => true, :copsDefect => true},
  # Mechanisms: Micro Contributions
  {:label => "Micro: Forum",
   :type => :normal, :calculation => :real, :legitimacyCalculation => :activism, :friends => :random, :medium => :forum, :mediumCensorship => :micro, :copsDefect => true},
  {:label => "Micro: Facebook",
   :type => :normal, :calculation => :real, :legitimacyCalculation => :activism, :friends => :random, :medium => :facebookWall, :mediumCensorship => :micro, :copsDefect => true},
  {:label => "Micro: Reallife",
   :type => :normal, :suppression => :micro, :calculation => :real, :legitimacyCalculation => :activism, :friends => :random, :medium => :none, :copsDefect => true},
  # Mechanisms: Grievance Exposure & Coordination
  {:label => "Exposure: Basic with friends",
   :type => :normal, :calculation => :real, :legitimacyCalculation => :activism, :friends => :random, :medium => :none, :copsDefect => true},
  {:label => "Exposure: Basic with fearless",
   :type => :normal, :suppression => :fearless, :calculation => :real, :legitimacyCalculation => :activism, :friends => :random, :medium => :none, :copsDefect => true},
  {:label => "Exposure: Forum",
   :type => :normal, :calculation => :real, :legitimacyCalculation => :activism, :friends => :random, :medium => :forum, :mediumCensorship => :uncensored, :copsDefect => true},
  {:label => "Exposure: Facebook",
   :type => :normal, :calculation => :real, :legitimacyCalculation => :activism, :friends => :random, :medium => :facebookWall, :mediumCensorship => :uncensored, :copsDefect => true},
  {:label => "Ex Coordination: Synchronize",
   :type => :normal, :calculation => :real, :legitimacyCalculation => :activism, :friends => :random, :medium => :none, :synchronizeProtest => true, :copsDefect => true},
  {:label => "Ex Coordination: Coordinate",
   :type => :normal, :calculation => :real, :legitimacyCalculation => :activism, :friends => :random, :medium => :none, :coordinateProtest => true, :copsDefect => true},
  {:label => "Ex Coordination: Coordinate with Notify",
   :type => :normal, :calculation => :real, :legitimacyCalculation => :activism, :friends => :random, :medium => :none, :coordinateProtest => true, :notifyOfProtest => true, :copsDefect => true},
  # Mechanisms: Citizen Journalism
  #{:label => "Citizen: Forum and Evidence",
  # :type => :normal, :calculation => :real, :legitimacyCalculation => :evidence, :friends => :random, :medium => :forum, :mediumCensorship => :normal, :copsDefect => true},
  #{:label => "Citizen: TV and Evidence",
  # :type => :normal, :calculation => :real, :legitimacyCalculation => :evidence, :friends => :random, :medium => :tv, :mediumCensorship => :normal, :copsDefect => true},

  # see :label => "Medium; tv, total censorship",
]

#setups = [
#  {:label => "Legitimacy affected by activism",
#   :type => :normal, :calculation => :real, :legitimacyCalculation => :activism, :friends => :none, :medium => :tv, :copsDefect => true},
#  {:label => "Epstein basic",
#   :type => :normal, :calculation => :epstein, :legitimacyCalculation => :normal, :friends => :none, :medium => :none},
#]

def clear_experiments()
  files = Dir.glob("experiments/*")
  if !files.empty?
    time = Time.now
    `mv experiments experiments.#{time.strftime("%Y-%b-%d-%H%M-%S")}`
    `mv setups setups.#{time.strftime("%Y-%b-%d-%H%M-%S")}`
    `mkdir experiments`
    `mkdir setups`
  end
end

def prepare_experiments(setups, experimentTicks, media_setups = nil, offset = 0)
  i = offset
  setups.each do |setup|
    expanded_setup = []

    setup_set = prepare_setup(setup, experimentTicks, media_setups)
  
    setup_nr = 0
    setup_set.each do |setup|
      setup[:experimentReruns].times do
        expanded_setup << setup.merge({:experimentSetupNr => setup_nr})
      end
      setup_nr += 1
    end

    file_label = setup[:label].downcase.gsub(/[^a-z0-9\s]/,'').gsub(/\s/, '-')
    old_files = Dir.glob("setups/#{i}.*")
    old_files.each do |old_file|
      `rm #{old_file}`
    end
    File.write("setups/#{i.to_s.rjust(3, "0")}.#{file_label}.json", JSON.pretty_generate(expanded_setup))
    i += 1
  end
end

def prepare_setup(setup, experimentTicks, media_setups)
  set = []

  media_setups.each do |media_setup|
    new_label = media_setup[:label] + " " + setup[:label]
    set << media_setup.merge(setup).merge({:label => new_label})
  end

  config = get_config()

  set.each do |setup|
    # Expand setting shortcuts
    if setup[:medium]
      setup[:media] = [setup[:medium]]
      setup.delete(:medium)
    end

    if setup[:experimentChange]
      setup[:experimentChanges] = [setup[:experimentChange]]
      setup.delete(:experimentChange)
    end

    setup[:experimentTicks] ||= experimentTicks

    # Replace hash strings by integers
    if setup[:media]
      media = setup[:media]
      setup[:media] = []
      media.each do |medium|
        setup[:media] << replace_config_key(medium, config[:hashes][:medium])
      end
    end

    config[:hashes].each do |key, config_hash|
      if setup[key]
        setup[key] = replace_config_key(setup[key], config_hash)
      end
    end

    if setup[:experimentChanges]
      setup[:experimentChanges].sort_by!(:tick)
      setup[:experimentChanges].each do |changes|
        config[:hashes].each do |key, value|
          if changes[key]
            changes[key] = replace_config_key(changes[key], value)
          end
        end
      end
    end
  end

  return set
end

def replace_config_key(key, hash)
  if key and key.is_a? Symbol
    integer = hash[key]
    if !integer.is_a? Integer
      raise "No setting for string '#{key}', typo? Hash #{hash.inspect}"
    end
    return integer
  else
    return key
  end
end

def get_config
  config_string = `./coffee experimenter.coffee --json=config`
  config = JSON.parse(config_string, :symbolize_names => true)
  return config
end

#setups = [
#  {:label => "Landscape: Pre",
#   :type => :normal, :calculation => :real, :legitimacyCalculation => :activism, :friends => :random, :media => [:tv, :newspaper, :telephone], :mediumCensorship => :uncensored, :copsDefect => true},
#  {:label => "Landscape: Early",
#   :type => :normal, :calculation => :real, :legitimacyCalculation => :activism, :friends => :random, :media => [:email, :website, :forum], :mediumCensorship => :micro, :copsDefect => true},
#  {:label => "Landscape: Late",
#   :type => :normal, :calculation => :real, :legitimacyCalculation => :activism, :friends => :random, :medium => :facebookWall, :mediumCensorship => :micro, :copsDefect => true}
#]

def run_experiment(setup_file, args)
  cmd = "./coffee experimenter.coffee --experiment=#{setup_file}#{args}"
  puts cmd

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

  list = Dir.glob("experiments/*.js")

  list.reject! {|f| f =~ /experiments.js/}
  list.each {|f| f.gsub!(/experiments\//, "")}
  list.sort!

  prefix = setup_file.gsub(/setups\//, '').gsub(/.json/,'')

  new_experiment_file = prefix + "." + Time.now.to_i.to_s + ".js"

  open("experiments/" + new_experiment_file, "w") do |file|
    file.write("experiment = eval('(" + experiment + ")');")
  end

  list.push(new_experiment_file)

  open("experiments/experiments.js", "w") do |file|
    file.write("experiments = eval('([\"" + list.join('", "') + "\"])');")
  end
end

# ./experimenter.rb --mode=single # for single-threaded
# ./experimenter.rb --clear # backup experiments
args = ""
only_clear = false
if ARGV[0] == "--clear"
  only_clear = true
elsif ARGV.length > 0
  args = " " + ARGV.join(" ")
end

setup_files = Dir.glob("setups/*").collect {|s| s.gsub(/setups\//, '')}
experiment_files = Dir.glob("experiments/*.js").collect {|e| e.gsub(/experiments\//, '')}

# If all setups are done, create a new empty experiment & setups folder
if setup_files.length + 1 == experiment_files.length and !setup_files.empty?
  clear_experiments()
elsif only_clear
  puts "Not clearing, not finished yet!"
end
exit if only_clear

# Prepare setup files
prepare_experiments(setups, experimentTicks, media_setups)
setup_files = Dir.glob("setups/*").collect {|e| e.gsub(/setups\//, '')}

# Rid of setups for which experiments already done
e_numbers = experiment_files.collect {|e| e.split('.')[0]}
e_numbers.each do |e_number|
  setup_files.reject! {|s| s =~ /^#{e_number}/}
end

setup_files.sort!
setup_files.collect! {|e| "setups/" + e}

setup_files.each do |setup_file|
  run_experiment(setup_file, args)
end
