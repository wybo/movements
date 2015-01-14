class Initializer extends Model
  startup: ->
    @communication = new Communication(this)
    window.modelUI = new UI(this)

  setup: ->
    @agents.setUseSprites() # Bitmap for better performance.
    @animator.setRate 20, false
    super()

# Initialization

window.initialize = (options) ->
  window.model = new Initializer({
    Agent: Agent
    div: "world"
    patchSize: 20
    mapSize: 20
    isTorus: true
    config: config
  })
  window.model.start() # Debug: Put Model vars in global name space

window.reInitialize = (options) ->
  contexts = window.model.contexts
  for bull, context of contexts
    context.canvas.width = context.canvas.width
  window.initialize(options)

$("#model_container").append('<div id="media"></div>')

config = new Config

window.initialize(config)
