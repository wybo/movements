class Initializer extends Model
  startup: ->
    @communication = new Communication(this)
    window.modelUI = new UI(this)

  setup: ->
    @agents.setUseSprites() # Bitmap for better performance.
    @animator.setRate 20, false
    super()

# Initialization

config = new Config

window.initialize = (config) ->
  window.model = new Initializer(
    u.merge(config.modelOptions, {config: config}))
  window.model.start()

window.reInitialize = ->
  contexts = window.model.contexts
  for bull, context of contexts
    context.canvas.width = context.canvas.width
  window.initialize(window.model.config)

$("#model_container").append('<div id="media"></div>')

window.initialize(config)
