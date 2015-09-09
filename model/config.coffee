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
MM.MEDIA = indexHash(["none", "email", "website", "forum", "facebook_wall"])
MM.MEDIUM_TYPES = indexHash(["normal", "micro", "uncensored"])
MM.VIEWS = indexHash(["none", "risk_aversion", "hardship", "grievance", "arrest_probability", "net_risk", "follow"])
# turn back to numbers once dat.gui fixed

console.log MM.VIEWS

class MM.Config
  type: MM.TYPES.normal
  calculation: MM.CALCULATIONS.real
  medium: MM.MEDIA.facebook_wall
  mediumType: MM.MEDIUM_TYPES.micro
  view: MM.VIEWS.arrest_probability
  
  copsRetreat: true
  activesAdvance: false
  excitement: true
  friends: 50
  friendsMultiplier: 2
  mediumCountsFor: 5

  citizenDensity: 0.7
  #copDensity: 0.04
  #copDensity: 0.012
  copDensity: 0.025
  maxPrisonSentence: 30 # J
  regimeLegitimacy: 0.82 # L
  threshold: 0.1
  thresholdMicro: 0.0
  #vision: {diamond: 7} # Neumann 7, v and v*
  vision: {radius: 7} # Neumann 7, v and v*
  walk: {radius: 2} # Neumann 7, v and v*
  kConstant: 2.3 # k

  ui: {
    passives: {label: "Passives", color: "green"},
    actives: {label: "Actives", color: "red"},
    prisoners: {label: "Prisoners", color: "black"},
    cops: {label: "Cops", color: "blue"},
    media: {label: "Media", color: "black"}
    micros: {label: "Micros", color: "orange"},
  }

  # ### Do not modify below unless you know what you're doing.

  constructor: ->
    sharedModelOptions = {
      Agent: MM.Agent
      patchSize: 20
      #mapSize: 15
      #mapSize: 20
      mapSize: 20
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
      patchSize: 10
      min: {x: 0, y: 0}
      max: {x: 39, y: 39}
    }

    @config = @

  makeHeadless: ->
    @modelOptions.isHeadless = @mediaModelOptions.isHeadless = true
