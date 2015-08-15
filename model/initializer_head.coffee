config = new MM.Config

window.initialize = (config) ->
  window.model = MM.Initializer.initialize()
  window.model.start()

window.reInitialize = ->
  contexts = window.model.contexts
  for bull, context of contexts
    context.canvas.width = context.canvas.width
  window.initialize(window.model.config)

$("#model_container").append('<div id="state"></div>')
$("#model_container").append('<div id="media"></div>')

window.initialize(config)
