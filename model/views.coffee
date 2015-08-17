class MM.Views
  constructor: (model, options = {}) ->
    @model = model

    @views = new ABM.Array

    @views[MM.VIEWS.none] = new MM.ViewNone(@model.config.viewModelOptions)
    @views[MM.VIEWS.grievances] = new MM.ViewGrievance(@model.config.viewModelOptions)
    @views[MM.VIEWS.arrest_probability] = new MM.ViewArrestProbability(@model.config.viewModelOptions)
    @views[MM.VIEWS.net_risk] = new MM.ViewNetRisk(@model.config.viewModelOptions)
    @views[MM.VIEWS.follow] = new MM.ViewFollow(@model.config.viewModelOptions)

    @updateOld()

  current: ->
    @views[@model.config.view]

  old: ->
    @views[@model.config.oldView]

  updateOld: ->
    @model.config.oldView = @model.config.view
