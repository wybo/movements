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
    hash[key] = "#{i++}"

  return hash

MM.TYPES = indexHash(["normal", "enclave", "focal_point", "micro"])
MM.CALCULATIONS = indexHash(["epstein", "wilensky", "overpowered", "real"])
MM.LEGITIMACY_CALCULATIONS = indexHash(["base", "arrests"])
MM.MEDIA = indexHash(["none", "tv", "newspaper", "telephone", "email", "website", "forum", "facebook_wall"])
MM.MEDIUM_TYPES = indexHash(["normal", "micro", "uncensored"])
MM.VIEWS = indexHash(["none", "risk_aversion", "hardship", "grievance", "regime_legitimacy", "arrest_probability", "net_risk", "follow"])
# turn back to numbers once dat.gui fixed

class MM.Config
  constructor: ->
    @type = MM.TYPES.normal
    @calculation = MM.CALCULATIONS.real
    @legitimacyCalculation = MM.LEGITIMACY_CALCULATIONS.arrests
    @medium = MM.MEDIA.telephone
    @mediumType = MM.MEDIUM_TYPES.normal
    @view = MM.VIEWS.arrest_probability
    
    @copsRetreat = false
    @activesAdvance = false
    @friends = 50 # also used for Fb
    @friendsMultiplier = 1 # 1 actively cancels out friends
    @friendsHardshipHomophilous = true
    @mediumCountsFor = 0.20
    #@mediumCountsFor = 0.25

    @citizenDensity = 0.7
    #@copDensity = 0.04
    #@copDensity = 0.012
    @copDensity = 0.03
    @arrestDuration = 2
    @maxPrisonSentence = 30 # J
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
      cops: {label: "Cops", color: "blue"},
      media: {label: "Media", color: "black"}
    }

    # ### Do not modify below unless you know what you're doing.

    sharedModelOptions = {
      Agent: MM.Agent
      patchSize: 20
      #mapSize: 15
      mapSize: 20
      #mapSize: 30
      isTorus: true
    }

    @modelOptions = u.merge(sharedModelOptions, {
      div: "world"
      # config is added
    })

    @viewModelOptions = u.merge(sharedModelOptions, {
      div: "view"
    })

    @mediaModelOptions = {
      Agent: MM.Agent
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

  makeHeadless: ->
    @modelOptions.isHeadless = @mediaModelOptions.isHeadless = true
