@MM = MM = {}

if typeof ABM == 'undefined'
  code = require "./lib/agentbase.coffee"
  eval 'var ABM = this.ABM = code.ABM'

u = ABM.util # ABM.util alias
log = (object) -> console.log object

MM.TYPES = {normal: "0", enclave: "1", micro: "2"}
MM.MEDIA = {none: 0, email: "1", website: "2", forum: "3"}
MM.VIEWS = {none: 0, grievances: "1", arrest_probability: "2", net_risk: "3", follow: "4"}
# turn back to numbers once dat.gui fixed

class MM.Config
  medium: MM.MEDIA.none
#  medium: MM.MEDIA.email
#  medium: MM.MEDIA.forum
#  medium: MM.MEDIA.website

  type: MM.TYPES.normal

#  view: MM.VIEWS.none
  view: MM.VIEWS.arrest_probability
#  view: MM.VIEWS.net_risk
#  view: MM.VIEWS.follow

  citizenDensity: 0.7
  #copDensity: 0.02
  #copDensity: 0.012
  copDensity: 0.04
  maxPrisonSentence: 30 # J
  regimeLegitimacy: 0.82 # L
  threshold: 0.1
  thresholdMicro: 0.0
  #vision: {diamond: 7} # Neumann 7, v and v*
  vision: {radius: 7} # Neumann 7, v and v*
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
