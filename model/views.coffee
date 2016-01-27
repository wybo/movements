class MM.Views
  constructor: (model, options = {}) ->
    @model = model

    @views = new ABM.Array

    genericView = new MM.ViewGeneric(u.merge(@model.config.viewModelOptions, {config: @model.config}))

    for key, viewNumber of MM.VIEWS
      @views[viewNumber] = genericView

    @views[MM.VIEWS.none] = new MM.ViewNone(@model.config.viewModelOptions)
    @views[MM.VIEWS.follow] = new MM.ViewFollow(@model.config.viewModelOptions)

    @updateOld()

  current: ->
    @views[@model.config.view]

  old: ->
    @views[@model.config.oldView]

  updateOld: ->
    @model.config.oldView = @model.config.view
