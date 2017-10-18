class MM.Views
  constructor: (model, options = {}) ->
    @model = model

    @views = new ABM.Array

    options = u.merge(@model.config.modelOptions, {config: @model.config, originalModel: @model, div: "view"})
    mediaOptions = u.merge(@model.config.mediaModelOptions, {config: @model.config, div: "view"})

    @views[MM.VIEWS.follow] = new MM.ViewFollow(options)

    @initializeView("tv", MM.ViewMediumTV, mediaOptions)
    @initializeView("newspaper", MM.ViewMediumNewspaper, mediaOptions)
    @initializeView("telephone", MM.ViewMediumTelephone, mediaOptions)
    @initializeView("email", MM.ViewMediumGenericDelivery, mediaOptions)
    @initializeView("website", MM.ViewMediumWebsite, mediaOptions)
    @initializeView("forum", MM.ViewMediumForum, mediaOptions)
    @initializeView("facebookWall", MM.ViewMediumGenericDelivery, mediaOptions)
    @initializeView("twitter", MM.ViewMediumGenericDelivery, mediaOptions)

    # Fill in with generic view otherwise
    genericView = new MM.ViewGeneric(options)

    for key, viewNumber of MM.VIEWS
      @views[viewNumber] ?= genericView

    @updateOld()

  initializeView: (name, klass, options) ->
    options = u.merge(options, {originalModel: @model.media.media[MM.MEDIA[name]]})
    @views[MM.VIEWS[name]] = new klass(options)

  current: ->
    @views[@model.config.view]

  old: ->
    @views[@model.config.oldView]

  updateOld: ->
    @model.config.oldView = @model.config.view

  changed: ->
    @old().reset()
    @current().reset()
    @current().populate()
    @current().start()
    @updateOld()
