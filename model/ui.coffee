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
    @setupPlot()

  setupControls: () ->
    settings =
      type: [MM.TYPES]
      #medium: [MM.MEDIA], {onChange: 55}
      medium: [MM.MEDIA]
      citizenDensity: {min: 0, max: 1}
      copDensity: {min: 0, max: 0.10}

    buttons =
      step: ->
        window.model.once()
      pauseResume: ->
        window.model.toggle()
      restart: ->
        window.model.restart()

    for key, value of settings
      if u.isArray(value)
        if key == "medium"
          adder = @gui.add(@model.config, key, value...)
          adder.onChange((newMedium) =>
            @model.communication.oldMedium().reset()
            @model.communication.medium().restart()
            @model.communication.updateOldMedium()
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

  setupPlot: () ->
    @plotOptions = {
      series: {
        shadowSize: 0
      } # faster without shadows
      xaxis: {
        show: false
      }
      yaxis: {
        min: 0
      }
      grid: {
        markings: []
      }
    }

  resetPlot: ->
    @plotRioters = []
    @plotRioters.push({label: "Passives", color: "green", data: []})
    @plotRioters.push({label: "Actives", color: "red", data: []})
    @plotRioters.push({label: "Prisoners", color: "black", data: []})
    @plotRioters.push({label: "Cops", color: "blue", data: []})
    @plotRioters.push({label: "Micros", color: "orange", data: []})
    @plotRioters.push({color: "black", data: []})
    @plotter = $.plot(@plotDiv, @plotRioters, @plotOptions)
    @drawPlot(0)

  drawPlot: (ticks) ->
    @plotRioters.data = []
    citizens = @model.citizens.length
    actives = @model.actives().length
    micros = @model.micros().length
    prisoners = @model.prisoners().length
    passives = citizens - actives - micros - prisoners
    cops = @model.cops.length
    @plotRioters[0].data.push [ticks, passives]
    @plotRioters[1].data.push [ticks, actives]
    @plotRioters[2].data.push [ticks, prisoners]
    @plotRioters[3].data.push [ticks, cops]
    @plotRioters[4].data.push [ticks, micros]
    if @mediaMarker
      @plotRioters[5].data.push [ticks, 0], [ticks, citizens], null
      @mediaMarker = false
    @plotter.setData(@plotRioters)
    @plotter.setupGrid()
    @plotter.draw()

  addMediaMarker: ->
    @mediaMarker = true
    console.log "Adding MEDIA MARKER"

