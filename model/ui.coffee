class MM.UI
  constructor: (model, options = {}) ->
    if window.modelUI
      window.modelUI.gui.domElement.remove()

    element = $("#graph")

    if element.lenght > 0
      element.remove()
    
    $("#model_container").append(
      #  '<div id="graph" style="width: 400px; height: 250px;"></div>')
      '<div id="graph" style="width: 800px; height: 500px;"></div>')

    @model = model
    @plotDiv = $("#graph")
    @gui = new dat.GUI()
    @setupControls()

  setupControls: () ->
    settings =
      type: [MM.TYPES]
      calculation: [MM.CALCULATIONS]
      medium: [MM.MEDIA]
      mediumType: [MM.MEDIUM_TYPES]
      view: [MM.VIEWS]
      #medium: [MM.MEDIA], {onChange: 55}
      citizenDensity: {min: 0, max: 1}
      copDensity: {min: 0, max: 0.10}
      maxPrisonSentence: {min: 0, max: 1000}
      regimeLegitimacy: {min: 0, max: 1}
      threshold: {min: -1, max: 1}
      thresholdMicro: {min: -1, max: 1}
      copsRetreat: null
      activesAdvance: null
      excitement: null
      friends: null
      friendsMultiplier: {min: 1, max: 5}
      mediumCountsFor: {min: 0, max: 20}

    buttons =
      step: ->
        window.model.once()
      pauseResume: ->
        window.model.toggle()
      restart: ->
        window.model.restart()

    for key, value of settings
      if u.isArray(value)
        if key == "view"
          adder = @gui.add(@model.config, key, value...)
          adder.onChange((newView) =>
            @model.views.old().reset()
            @model.views.current().reset()
            @model.views.current().populate(@model)
            @model.views.current().start()
            @model.views.updateOld()
          )
        else if key == "medium"
          adder = @gui.add(@model.config, key, value...)
          adder.onChange((newMedium) =>
            @model.media.old().reset()
            @model.media.current().restart()
            @model.media.updateOld()
            @addMediaMarker()
          )
        else
          @gui.add(@model.config, key, value...)
      else
        adder = @gui.add(@model.config, key)
        for setting, argument of value
          adder[setting](argument)

    for key, bull of buttons
      @gui.add(buttons, key)


  resetPlot: ->
    options = {
      series: {
        shadowSize: 0
      } # faster without shadows
      yaxis: {
        min: 0
      }
      grid: {
        markings: [
          { color: "#000", lineWidth: 1, xaxis: { from: 2, to: 2 } }
        ]
      }
    }

    @model.resetData()
    @plotRioters = []
    for key, variable of @model.config.ui
      @plotRioters.push({
        label: variable.label, color: variable.color, data: @model.data[key]
      })

    @plotter = $.plot(@plotDiv, @plotRioters, options)
    @plotOptions = @plotter.getOptions()
    @drawPlot()

  drawPlot: ->
    @plotter.setData(@plotRioters)
    @plotter.setupGrid()
    @plotter.draw()

  addMediaMarker: ->
    ticks = @model.animator.ticks
    @plotOptions.grid.markings.push { color: "#000", lineWidth: 1, xaxis: { from: ticks, to: ticks } }
