@MM = MM = {}

if typeof ABM == 'undefined'
  code = require "./lib/agentbase.coffee"
  eval 'var ABM = this.ABM = code.ABM'

u = ABM.util # ABM.util alias
log = (object) -> console.log object

MM.TYPES = {normal: "0", enclave: "1", micro: "2"}
MM.MEDIA = {none: 0, email: "1", website: "2", forum: "3"}
# turn back to numbers once dat.gui fixed

class MM.Config
#  medium: MEDIA.none
#  medium: MEDIA.email
  medium: MM.MEDIA.forum
#  medium: MEDIA.website

  type: MM.TYPES.normal

  citizenDensity: 0.7
  #copDensity: 0.02
  copDensity: 0.012

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
    }

    @modelOptions = u.merge(sharedModelOptions, {
      div: "world"
      patchSize: 20
      mapSize: 20
      isTorus: true
      # config is added
    })

    @mediaModelOptions = u.merge(sharedModelOptions, {
      div: "media"
      patchSize: 10
      min: {x: 0, y: 0}
      max: {x: 109, y: 39}
    })

    @config = @

  makeHeadless: ->
    @modelOptions.isHeadless = @mediaModelOptions.isHeadless = true
