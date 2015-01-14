u = ABM.util # ABM.util alias
log = (object) -> console.log object

ABM.TYPES = {normal: "0", enclave: "1", micro: "2"}
ABM.MEDIA = {email: "0", website: "1", forum: "2"}
# turn back to numbers once dat.gui fixed

class Config
#  medium: ABM.MEDIA.email
  medium: ABM.MEDIA.forum
#  medium: ABM.MEDIA.website
#
  type: ABM.TYPES.normal

  citizenDensity: 0.7
  copDensity: 0.02

# Copyright 2014, Wybo Wiersma, available under the GPL v3
# This model builds upon Epsteins model of protest, and illustrates
# the possible impact of social media on protest formation.

class Medium extends ABM.Model
  setup: ->
    @size = 0.6

    # Shape to bitmap for better performance.
    @agents.setUseSprites()

    @animator.setRate 20, false

    @dummyAgent = {position: {x: 0, y: @world.max.y}, color: u.color.lightgray, twin: {active: false}, dummy: true}

    for patch in @patches.create()
      patch.color = u.color.white

  createAgent: (twin) ->
    @agents.create 1
    agent = @agents.last()
    agent.size = @size
    agent.heading = u.degreesToRadians(270)
    agent.twin = twin
    agent.color = twin.color

    return agent

  colorPost: (patch, agent) ->
    if agent.twin.active
      patch.color = u.color.orange
    else
      patch.color = u.color.lightgray

class Agent extends ABM.Agent
  setColor: (color) ->
    @color = new u.color color
    @sprite = null

  moveToRandomEmptyLocation: ->
    @moveTo(@model.patches.sample((patch) -> patch.empty()).position)

  randomEmptyNeighbor: ->
    @patch.neighbors(@vision).sample((patch) -> patch.empty())

class Communication
  constructor: (model, options = {}) ->
    @model = model

    medium_hash = {
      div: "media"
      patchSize: 20
      min: {x: 0, y: 0}
      max: {x: 19, y: 19}
    }

    @media = new ABM.Array
    @media[ABM.MEDIA.forum] = new Forum(medium_hash)
    @media[ABM.MEDIA.website] = new Website(medium_hash)
    @media[ABM.MEDIA.email] = new EMail(medium_hash)

    @updateOldMedium()

  medium: ->
    @media[@model.config.medium]

  oldMedium: ->
    @media[@model.config.oldMedium]

  updateOldMedium: ->
    @model.config.oldMedium = @model.config.medium

class EMail extends Medium
  setup: ->
    super

  step: ->
    for agent in @agents
      if u.randomInt(20) == 1
        @newMail(agent)
      else
        @readMessage(agent)

    @setPatches()

  setPatches: ->
    x_offset = y_offset = 0
    for agent, i in @agents
      x = i %% (@world.max.x + 1)
      y_offset = Math.floor(i / (@world.max.x + 1)) * 5

      for message, j in agent.inbox
        patch = @patches.patch(x: x, y: y_offset + j)

        @colorPost(patch, twin: message)
        lastPatch = patch

      if lastPatch?
        white = @patches.patch x: lastPatch.position.x, y: lastPatch.position.y + 1
        white.color = u.color.white

      agent.moveTo x: x, y: y_offset

  use: (twin) ->
    agent = @createAgent(twin)
    agent.inbox = Message.inbox(agent)

  newMail: (agent) ->
    new Message from: agent, to: @agents.sample(), active: agent.twin.active

  readMessage: (agent) ->
    message = Message.read(agent)

class Forum extends Medium
  setup: ->
    super

    @newThread(@dummyAgent)

    while @messages.length < @world.max.x
      @newPost(@dummyAgent)

  step: ->
    for agent in @agents by -1
      if u.randomInt(20) == 1
        @newPost(agent)
      else
        agent.forward 1, snap: true
        if agent.patch.color == u.color.white or agent.position.y == 0
          agent.moveTo(x: agent.position.x + 1, y: @world.max.y)
      if agent.position.x > @world.max.x
        agent.die()

  use: (twin) ->
    agent = @createAgent(twin)
    agent.moveTo(x: 0, y: @world.max.y)

  newPost: (agent) ->
    if u.randomInt(7) == 1
      @newThread(agent)
    else
      @newComment(agent)

  newThread: (agent) ->
    opener = null

    for patch in @patches by -1
      if patch.position.x > 0
        previous = @patches.patch x: patch.position.x - 1, y: patch.position.y
        patch.color = previous.color
        for agent in previous.agents by -1
          agent.moveTo patch.position
      else
        if patch.position.y == @world.max.y
          opener = patch
        else
          patch.color = u.color.white

    @colorPost(opener, agent)

    @messages.unshift new ABM.Array opener
    if @messages.length > @world.max.x
      @messages.pop

  newComment: (agent) ->
    patch = @patches.patch(x: agent.position.x, y: @messages[agent.position.x].last().position.y - 1)
    @colorPost(patch, agent)
    @messages[agent.position.x].push patch

class Message
  constructor: (options) ->
    @from = options.from
    @active = options.active

class UI
  constructor: (model, options = {}) ->
    if window.modelUI
      window.modelUI.gui.domElement.remove()

    element = $("#graph")

    if element.lenght > 0
      element.remove()
    
    $("#model_container").append(
      '<div id="graph" style="width: 400px; height: 250px;"></div>')
    #  '<div id="graph" style="width: 800px; height: 500px;"></div>')

    @model = model
    @plotDiv = $("#graph")
    @gui = new dat.GUI()
    @setupControls()
    @setupPlot()

  setupControls: () ->
    settings =
      type: [ABM.TYPES]
      #medium: [ABM.MEDIA], {onChange: 55}
      medium: [ABM.MEDIA]
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

class Website extends Medium
  setup: ->
    super

    while @messages.length < 100
      @newPage(@dummyAgent)

  step: ->
    for agent in @agents
      if u.randomInt(20) == 1
        @newPage(agent)
      else
        agent.moveTo(@messages.sample().position)

  use: (twin) ->
    agent = @createAgent(twin)
    agent.moveTo(@messages.sample().position)

  newPage: (agent) ->
    patch = @patches.sample()
    @colorPost(patch, agent)

    @messages.unshift patch
    if @messages.length > 100
      oldPage = @messages.pop()
      oldPage.color = u.color.white

class Model extends ABM.Model
  setup: ->
    @agentBreeds ["citizens", "cops"]
    @size = 0.9
    @vision = {diamond: 7} # Neumann 7

    for patch in @patches.create()
      if @config.type is ABM.TYPES.enclave
        if patch.position.y > 0
          patch.color = u.color.random type: "gray", min: 180, max: 204
        else
          patch.color = u.color.random type: "gray", min: 234, max: 255
      else
        patch.color = u.color.random type: "gray", min: 224, max: 255

    space = @patches.length

    for citizen in @citizens.create @config.citizenDensity * space
      citizen.vision = @vision
      citizen.size = @size
      citizen.shape = "person"
      citizen.setColor "green"
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
        activation = @grievance() - @netRisk()

        if @model.config.type is ABM.TYPES.micro
          if activation > @threshold
            @active = true
            @setColor "red"
            @activeMicro = 1.0
          else if activation > @thresholdMicro
            @active = false
            @setColor "orange"
            @activeMicro = 0.4
          else
            @active = false
            @setColor "green"
            @activeMicro = 0.0

        else
          if activation > @threshold
            @active = true
            @setColor "red"
          else
            @active = false
            @setColor "green"

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
      cop.setColor "blue"
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

    window.modelUI.resetPlot()

  step: -> # called by Model.animate
    @agents.shuffle()
    for agent in @agents
      agent.act()
      if u.randomInt(500) == 1
        if agent.breed.name is "citizens"
          @communication.medium().use(agent)

    window.modelUI.drawPlot(@animator.ticks)

    @communication.medium().once()

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

class Initializer extends Model
  startup: ->
    @communication = new Communication(this)
    window.modelUI = new UI(this)

  setup: ->
    @agents.setUseSprites() # Bitmap for better performance.
    @animator.setRate 20, false
    super()

# Initialization

window.initialize = (options) ->
  window.model = new Initializer({
    Agent: Agent
    div: "world"
    patchSize: 20
    mapSize: 20
    isTorus: true
    config: config
  })
  window.model.start() # Debug: Put Model vars in global name space

window.reInitialize = (options) ->
  contexts = window.model.contexts
  for bull, context of contexts
    context.canvas.width = context.canvas.width
  window.initialize(options)

$("#model_container").append('<div id="media"></div>')

config = new Config

window.initialize(config)
