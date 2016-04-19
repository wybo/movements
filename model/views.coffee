class MM.Views
  constructor: (model, options = {}) ->
    @model = model

    @views = new ABM.Array

    genericView = new MM.ViewGeneric(u.merge(@model.config.viewModelOptions, {config: @model.config, originalModel: @model}))

    @views[MM.VIEWS.none] = new MM.ViewNone(u.merge(@model.config.viewModelOptions, {config: @model.config, originalModel: @model}))
    @views[MM.VIEWS.follow] = new MM.ViewFollow(u.merge(@model.config.viewModelOptions, {config: @model.config, originalModel: @model}))

    @initializeView("forum", MM.ViewMediumForum, "view")
    @initializeView("tv", MM.ViewMediumTV, "view")
    @initializeView("newspaper", MM.ViewMediumNewspaper, "view")
    @initializeView("telephone", MM.ViewMediumTelephone, "view")
    @initializeView("email", MM.ViewMediumGenericDelivery, "view")
    @initializeView("website", MM.ViewMediumWebsite, "view")
    @initializeView("facebookWall", MM.ViewMediumGenericDelivery, "view")

    for key, viewNumber of MM.VIEWS
      for mediaKey, mediaNumber of MM.MEDIA
        if key == mediaKey
          @views[viewNumber] ?= new MM.ViewMediumGeneric(
            u.merge(@model.config.mediaModelOptions, {config: @model.config, originalModel: @model.media.media[mediaNumber], div: "view"})
          )

      # Fill in with generic view otherwise
      @views[viewNumber] ?= genericView

    @updateOld()

  initializeView: (name, klass, div, options) ->
    options ?= @model.config.mediaModelOptions
    @views[MM.VIEWS[name]] = new klass(
      u.merge(options, {config: @model.config, originalModel: @model.media.media[MM.MEDIA[name]], div: "view"})
    )

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
