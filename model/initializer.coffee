class MM.Initializer extends MM.Model
  @initialize: (@config) ->
    @config ?= new MM.Config
    console.log @config
    return new MM.Initializer(u.merge(@config.modelOptions, {config: @config}))
    #return new MM.Initializer(@config) TODO
  
  startup: ->
    @media = new MM.Media(this)
    unless @isHeadless
      @views = new MM.Views(this)
      window.modelUI = new MM.UI(this)

  setup: ->
    @agents.setUseSprites() # Bitmap for better performance.
    @animator.setRate 20, false
    super()
