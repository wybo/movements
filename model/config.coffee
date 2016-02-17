# Copyright 2014, Wybo Wiersma, available under the GPL v3. Please
# cite with url, and author Wybo Wiersma (and if applicable, a paper).
# This model builds upon Epsteins model of protest, and illustrates
# the possible impact of social media on protest formation.

@MM = MM = {}

if typeof ABM == 'undefined'
  code = require "./lib/agentbase.coffee"
  eval 'var ABM = this.ABM = code.ABM'

u = ABM.util # ABM.util alias
log = (object) -> console.log object

indexHash = (array) ->
  hash = {}
  i = 0
  for key in array
    hash[key] = i++

  return hash

MM.TYPES = indexHash(["normal", "enclave", "focalPoint", "micro", "hold", "square"])
MM.CALCULATIONS = indexHash(["epstein", "wilensky", "overpowered", "real"])
MM.LEGITIMACY_CALCULATIONS = indexHash(["base", "arrests"])
MM.FRIENDS = indexHash(["none", "random", "cliques", "local"])
MM.MEDIA = indexHash(["none", "tv", "newspaper", "telephone", "email", "website", "forum", "facebookWall"])
MM.MEDIUM_TYPES = indexHash(["normal", "uncensored"]) # TODO micro, from original agent
MM.VIEWS = indexHash(["none", "riskAversion", "hardship", "grievance", "regimeLegitimacy", "arrestProbability", "netRisk", "follow"])
# turn back to numbers once dat.gui fixed

class MM.Config
  constructor: ->
    @testRun = false
    @type = MM.TYPES.square
    @calculation = MM.CALCULATIONS.real
    @legitimacyCalculation = MM.LEGITIMACY_CALCULATIONS.arrests
    @friends = MM.FRIENDS.local
    @medium = MM.MEDIA.forum
    @mediumType = MM.MEDIUM_TYPES.uncensored
    #@view = MM.VIEWS.regimeLegitimacy
    @view = MM.VIEWS.riskAversion
    
    @copsRetreat = false
    @activesAdvance = false
    @friendsNumber = 30 # also used for Fb
    @friendsMultiplier = 2 # 1 actively cancels out friends
    @friendsHardshipHomophilous = true # If true range has to be 6 min, and friends max 30 or will have fewer
    @friendsLocalRange = 6

    @mediaChannels = 7 # for media TV and radio

    @holdInterval = 100 # for hold type
    @holdReleaseDuration = 25

    @citizenDensity = 0.7
    #@copDensity = 0.04
    #@copDensity = 0.012
    @copDensity = 0.03
    @arrestDuration = 2
    @maxPrisonSentence = 30 # J
    #@baseRegimeLegitimacy = 0.85 # L
    #@baseRegimeLegitimacy = 0.80 # L
    @baseRegimeLegitimacy = 0.75 # L
    #@baseRegimeLegitimacy = 0.82 # best with base
    @threshold = 0.1
    @thresholdMicro = 0.0
    #@vision = {diamond: 7} # Neumann 7, v and v*
    @vision = {radius: 7} # Neumann 7, v and v*
    @walk = {radius: 2} # Neumann 7, v and v*
    @kConstant = 2.3 # k

    @ui = {
      passives: {label: "Passives", color: "green"},
      actives: {label: "Actives", color: "red"},
      micros: {label: "Micros", color: "orange"},
      arrests: {label: "Arrests", color: "purple"},
      prisoners: {label: "Prisoners", color: "black"},
      cops: {label: "Cops", color: "blue"}
    }
    # ### Do not modify below unless you know what you're doing.

    sharedModelOptions = {
      patchSize: 20
      #mapSize: 15
      mapSize: 20
      #mapSize: 30
      isTorus: true
    }

    @modelOptions = u.merge(sharedModelOptions, {
      Agent: MM.Agent
      div: "world"
      # config is added
    })

    @viewModelOptions = u.merge(sharedModelOptions, {
      div: "view"
    })

    @mediaModelOptions = {
      div: "medium"
      #patchSize: 15
      patchSize: 10
      min: {x: 0, y: 0}
      max: {x: 39, y: 39}
    }

    @mediaMirrorModelOptions = u.merge(sharedModelOptions, {
      div: "medium"
      # config is added
    })

    @config = @

    @check()

  makeHeadless: ->
    @modelOptions.isHeadless = true
    @viewModelOptions.isHeadless = true
    @mediaModelOptions.isHeadless = true
    @mediaMirrorModelOptions.isHeadless = true

    @check()

  check: ->
    if @testRun && @modelOptions.isHeadless
      throw "Cannot be a testRun if headless"

    if @friendsMultiplier < 1
      throw "friendsMultiplier should be 1 (cancels) or over"

    if @arrestDuration < 1 and MM.LEGITIMACY_CALCULATIONS.arrests == @legitimacyCalculation
      throw "arrests need to be visible for legitimacyCalculation"

    if @mediaChannels > @mediaModelOptions.max.x + 1
      throw "Too many channels for world size"

    for index in [@type, @calculation, @legitimacyCalculation, @friends, @medium, @mediumType, @view]
      if !u.isInteger(index)
        throw "Config index not integer!"
