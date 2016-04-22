config = new MM.Config

window.initialize = (config) ->
  window.model = MM.Initializer.initialize()
  window.model.start()

window.reInitialize = ->
  contexts = window.model.contexts
  for bull, context of contexts
    context.canvas.width = context.canvas.width
  window.initialize(window.model.config)

$("#model_container").after('<div id="before_graph" class="model_container" style="float: left;"><div id="view"></div></div>')

window.initialize(config)
