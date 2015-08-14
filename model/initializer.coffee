class MM.Initializer extends MM.Model
  @initialize: (@config) ->
    @config ?= new MM.Config
    console.log @config
    return new MM.Initializer(u.merge(@config.modelOptions, {config: @config}))
    #return new MM.Initializer(@config) TODO
  
  startup: ->
    @communication = new MM.Communication(this)
    unless @isHeadless
      window.modelUI = new MM.UI(this)

  setup: ->
    @agents.setUseSprites() # Bitmap for better performance.
    @animator.setRate 20, false
    super()
