#class MM.Initializer extends MM.ModelSimple
class MM.Initializer extends MM.Model
  @initialize: (@config) ->
    config ?= new MM.Config
    return new MM.Initializer(u.merge(config.modelOptions, {config: config}))
  
  startup: ->
    @media = new MM.Media(this)
    unless @isHeadless
      @views = new MM.Views(this)
      window.modelUI = new MM.UI(this)

  setup: ->
    @agents.setUseSprites() # Bitmap for better performance.
    @animator.setRate 20, false
    super()
