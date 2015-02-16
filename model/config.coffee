u = ABM.util # ABM.util alias
log = (object) -> console.log object

ABM.TYPES = {normal: "0", enclave: "1", micro: "2"}
ABM.MEDIA = {none: 0, email: "1", website: "2", forum: "3"}
# turn back to numbers once dat.gui fixed

class Config
#  medium: ABM.MEDIA.none
#  medium: ABM.MEDIA.email
  medium: ABM.MEDIA.forum
#  medium: ABM.MEDIA.website

  type: ABM.TYPES.normal

  citizenDensity: 0.7
  copDensity: 0.02

  # ### Do not modify below unless you know what you're doing.

  constructor: ->
    sharedModelOptions = {
      Agent: Agent
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
      patchSize: 20
      min: {x: 0, y: 0}
      max: {x: 19, y: 19}
    })
