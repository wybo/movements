@MM = MM = {}

if typeof ABM == 'undefined'
  code = require "./lib/agentbase.coffee"
  eval 'var ABM = this.ABM = code.ABM'

u = ABM.util # ABM.util alias
log = (object) -> console.log object

MM.TYPES = {normal: "0", enclave: "1", micro: "2"}
MM.CALCULATIONS = {epstein: "0", wilensky: "1", overpowered: "2", real: "3"}
MM.MEDIA = {none: 0, email: "1", website: "2", forum: "3"}
MM.VIEWS = {none: 0, grievance: "1", risk_aversion: "2", arrest_probability: "3", net_risk: "4", follow: "5"}
# turn back to numbers once dat.gui fixed

class MM.Config
  type: MM.TYPES.normal
#  type: MM.TYPES.enclave
#  type: MM.TYPES.micro

#  calculation: MM.CALCULATIONS.epstein
#  calculation: MM.CALCULATIONS.wilensky
#  calculation: MM.CALCULATIONS.overpowered
  calculation: MM.CALCULATIONS.real

  medium: MM.MEDIA.none
#  medium: MM.MEDIA.email
#  medium: MM.MEDIA.forum
#  medium: MM.MEDIA.website

#  view: MM.VIEWS.none
#  view: MM.VIEWS.grievance
#  view: MM.VIEWS.risk_aversion
  view: MM.VIEWS.arrest_probability
#  view: MM.VIEWS.net_risk
#  view: MM.VIEWS.follow

  citizenDensity: 0.7
  #copDensity: 0.04
  #copDensity: 0.012
  copDensity: 0.02
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
      #mapSize: 20
      mapSize: 30
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
