# Copyright 2014, Wybo Wiersma, available under the GPL v3
# This model builds upon Epsteins model of protest, and illustrates
# the possible impact of social media on protest formation.
#
u = ABM.util # ABM.util alias
log = (object) -> console.log object

ABM.TYPES = {normal: "0", enclave: "1", micro: "2"}
# turn back to numbers once dat.gui fixed

class Config
  type: ABM.TYPES.normal
  citizenDensity: 0.7
  copDensity: 0.02

class Model extends ABM.Model
  startup: ->
    @ui = new UI(this, plotDiv: "#graph")

  setup: ->
    @agentBreeds ["citizens", "cops"]
    @size = 0.9
    @vision = {diamond: 7} # Neumann 7

    console.log @config
    
    # Shape to bitmap for better performance.
    @agents.setUseSprites()

    @animator.setRate 20, false

    for patch in @patches.create()
      if @config.type is ABM.TYPES.enclave
        if patch.position.y > 0
          patch.color = u.randomGray(180, 204)
        else
          patch.color = u.randomGray(234, 255)
      else
        patch.color = u.randomGray(224, 255)

    space = @patches.length

    for citizen in @citizens.create @config.citizenDensity * space
      citizen.vision = @vision
      citizen.size = @size
      citizen.shape = "person"
      citizen.setColor("green")
      citizen.moveToRandomEmptyLocation()

      citizen.regimeLegitimacy = 0.32
      citizen.threshold = 0.1
      citizen.thresholdMicro = 0.0
      citizen.hardship = u.randomFloat()
      citizen.riskAversion = u.randomFloat()
      citizen.active = false
      citizen.activeMicro = 0.0
      citizen.prisonSentence = 0

      citizen.grievance = ->
        @hardship * (1 - @regimeLegitimacy)

      citizen.arrestProbability = ->
        cops = 0
        actives = 1
  
        for agent in @neighbors(@vision)
          if agent.breed.name is "cops"
            cops += 1
          else
            if @model.config.type is ABM.TYPES.micro
              if agent.breed.name is "citizen"
                actives += agent.activeMicro
            else
              if agent.breed.name is "citizen" and agent.active
                actives += 1

        1 - Math.exp(-2.3 * cops / actives)

      citizen.netRisk = ->
        @arrestProbability() * @riskAversion

      citizen.imprison = (sentence) ->
        @prisonSentence = sentence
        @moveOff()

      citizen.imprisoned = ->
        @prisonSentence > 0

      citizen.activate = ->
        if @model.config.type is ABM.TYPES.micro
          activation = @grievance() - @netRisk()

          if activation > @threshold
            @active = true
            @setColor("red")
            @activeMicro = 1.0
          else if activation > @thresholdMicro
            @active = false
            @setColor([255, 164, 0])
            @activeMicro = 0.4
          else
            @active = false
            @setColor("green")
            @activeMicro = 0.0

        else
          if @grievance() - @netRisk() > @threshold
            @active = true
            @setColor("red")
          else
            @active = false
            @setColor("green")

      citizen.act = ->
        if @imprisoned()
          @prisonSentence -= 1
          if !@imprisoned() # just released
            @moveToRandomEmptyLocation()
        if !@imprisoned() # just released included
          empty = @randomEmptyNeighbor()
          if @model.config.type is ABM.TYPES.enclave
            if empty and (@riskAversion > 0.5 and
                (empty.position.y > 0 or empty.position.y < 0 and
                  empty.position.y > @patch.position.y)) or
                (@riskAversion < 0.5 and
                (empty.position.y < 0 or empty.position.y > 0 and
                  empty.position.y < @patch.position.y))
              empty = @randomEmptyNeighbor()

          @moveTo(empty.position) if empty
          @activate()

    for cop in @cops.create @config.copDensity * space
      cop.vision = @vision
      cop.size = @size
      cop.shape = "person"
      cop.setColor("blue")
      cop.moveToRandomEmptyLocation()

      cop.maxPrisonSentence = 30

      cop.makeArrest = ->
        protesters = 0
        passives = 0
        for agent in @neighbors(@vision)
          if agent.breed.name is "citizens" and agent.active
            protesters += 1
          else
            passives += 1

        protester = @neighbors(@vision).sample((agent) ->
          agent.breed.name is "citizens" and agent.active)
        if protester
          protester.imprison(1 + u.randomInt(@maxPrisonSentence))

      cop.act = ->
        empty = @randomEmptyNeighbor()
        @moveTo(empty.position) if empty
        @makeArrest()

    @ui.resetPlot()

  prisoners: ->
    prisoners = []
    for citizen in @citizens
      if citizen.imprisoned()
        prisoners.push citizen
    prisoners

  actives: ->
    actives = []
    for citizen in @citizens
      if citizen.active and not citizen.imprisoned()
        actives.push citizen
    actives

  micros: ->
    micros = []
    for citizen in @citizens
      if !citizen.active and citizen.activeMicro > 0 and
          not citizen.imprisoned()
        micros.push citizen
    micros

  step: ->  # called by Model.animate
    @agents.shuffle()
    for agent in @agents
      agent.act()

    @ui.drawPlot(@animator.ticks)

    #@spriteSheet()

  spriteSheet: ->
    if @animator.draws is 2 # Show the sprite sheet if there is one after first draw
      sheet = u.last(u.s.spriteSheets) if u.s.spriteSheets.length isnt 0
      if sheet?
        log sheet
        document.getElementById("play").appendChild(sheet.canvas)

class Agent extends ABM.Agent
  setColor: (color) ->
    if u.isString color
      @color = u.colorFromString(color)
    else
      @color = color
    @sprite = null

  moveToRandomEmptyLocation: ->
    @moveTo(@model.patches.sample((patch) -> patch.empty()).position)

  randomEmptyNeighbor: ->
    @patch.neighbors(@vision).sample((patch) -> patch.empty())

class Forum extends ABM.Model
  setup: ->
    @agentBreeds ["citizens"]
    @size = 0.9

    # Shape to bitmap for better performance.
    @agents.setUseSprites()

    @animator.setRate 20, false

    for patch in @patches.create()
      patch.color = u.randomGray(224, 255)

class UI
  constructor: (model, options = {}) ->
    @model = model
    @plotDiv = $(options.plotDiv)
    @setupControls()
    @setupPlot()

  setupControls: () ->
    settings =
      type: [ABM.TYPES]
      citizenDensity: {min: 0, max: 1}
      copDensity: {min: 0, max: 0.10}

    buttons =
      step: ->
        window.model.once()
      pauseResume: ->
        window.model.toggle()
      restart: ->
        window.model.restart()

    gui = new dat.GUI()

    for key, value of settings
      if u.isArray(value)
        gui.add(@model.config, key, value...)
      else
        adder = gui.add(@model.config, key)
        for setting, argument of value
          adder[setting](argument)


    for key, bull of buttons
      gui.add(buttons, key)

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
    }

  resetPlot: ->
    @plotRioters = []
    @plotRioters.push({color: "green", data: []})
    @plotRioters.push({color: "red", data: []})
    @plotRioters.push({color: "black", data: []})
    @plotRioters.push({color: "blue", data: []})
    @plotRioters.push({color: "orange", data: []})
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
    @plotter.setData(@plotRioters)
    @plotter.setupGrid()
    @plotter.draw()

window.initialize = (options) ->
  window.model = new Model({
    Agent: Agent,
    div: "world",
    patchSize: 20,
    mapSize: 40
    isTorus: true,
    hasNeighbors: true,
    config: config,
  })
  window.model.start() # Debug: Put Model vars in global name space
#  window.forum = new Forum({
#    Agent: Agent,
#    div: "media",
#    patchSize: 10,
#    mapSize: 80
#    isTorus: true,
#    hasNeighbors: true
#  })
#  window.forum.start() # Debug: Put Model vars in global name space

window.reInitialize = (options) ->
  contexts = window.model.contexts
  for bull, context of contexts
    context.canvas.width = context.canvas.width
  window.initialize(options)

if !window.initializedDivs
  $("#model_container").append(
    '<div id="graph" style="width: 800px; height: 500px;"></div>')
  window.initializedDivs = true

config = new Config

window.initialize(config)
