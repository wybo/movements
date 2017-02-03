class MM.UI
  constructor: (model, options = {}) ->
    if window.modelUI
      window.modelUI.gui.domElement.remove()

    element = $("#graph")

    if element.lenght > 0
      element.remove()
    
    $("#before_graph").after(
      '<div class="model_container" style="float: left;"><div id="graph" style="width: 500px; height: 400px;"></div></div>')

    @model = model
    @plotDiv = $("#graph")
    @gui = new dat.GUI()
    @setupControls()

  setupControls: () ->
    dropdownHashes = {}
    for key, value of @model.config.hashes
      dropdownHashes[key] = [value]

    settings = u.merge dropdownHashes, {
      riskAversionDistributionNormal: null
      hardshipDistributionNormal: null
      smartPhones: null
      citizenDensity: {min: 0, max: 1}
      copDensity: {min: 0, max: 0.10}
      maxPrisonSentence: {min: 0, max: 1000}
      baseRegimeLegitimacy: {min: 0, max: 1}
      threshold: {min: -1, max: 1}
      thresholdMicro: {min: -1, max: 1}
      prisonCapacity: {min: 0, max: 1}
      copsRetreat: null
      copsDefect: null
      friendsNumber: null
      friendsMultiplier: {min: 0, max: 5}
      friendsHardshipHomophilous: null
      friendsLocalRange: 5
    }

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
          adder = @gui.add(@model.config, key, value...).listen()
        else
          adder = @gui.add(@model.config, key, value...)
        adder.onChange(@setDropdown(key, @))
      else
        adder = @gui.add(@model.config, key)
        for setting, argument of value
          adder[setting](argument)
        adder.onChange(@set(key, @))

    for key, bull of buttons
      @gui.add(buttons, key)

  set: (key, ui) -> return (value) -> # closure-fu to keep key
    ui.model.set(key, value)

  setDropdown: (key, ui) -> return (value) -> # closure-fu to keep key
    ui.model.set(key, parseInt(value))
    intValue = parseInt(value)
    if key == "medium"
      ui.model.set("view", MM.VIEWS[u.deIndexHash(MM.MEDIA)[intValue]])

  resetPlot: ->
    options = {
      series: {
        shadowSize: 0
      } # faster without shadows
      yaxis: {
        min: 0
      }
      grid: {
        markings: []
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
