@MM = MM = {}

if typeof ABM == 'undefined'
  code = require "./lib/agentbase.coffee"
  eval 'var ABM = this.ABM = code.ABM'

u = ABM.util # ABM.util alias
log = (object) -> console.log object

MM.TYPES = {normal: "0", enclave: "1", micro: "2"}
MM.MEDIA = {none: 0, email: "1", website: "2", forum: "3"}
# turn back to numbers once dat.gui fixed

class MM.Config
#  medium: MEDIA.none
#  medium: MEDIA.email
  medium: MM.MEDIA.forum
#  medium: MEDIA.website

  type: MM.TYPES.normal

  citizenDensity: 0.7
  copDensity: 0.02

  # ### Do not modify below unless you know what you're doing.

  constructor: ->
    sharedModelOptions = {
      Agent: MM.Agent
    }

    @modelOptions = u.merge(sharedModelOptions, {
      div: "world"
      patchSize: 20
      mapSize: 20
      isTorus: true
      # config is added
    })

    @mediaModelOptions = u.merge(sharedModelOptions, {
      div: "media"
      patchSize: 20
      min: {x: 0, y: 0}
      max: {x: 19, y: 19}
    })

    @config = @

  makeHeadless: ->
    @modelOptions.isHeadless = @mediaModelOptions.isHeadless = true

# Copyright 2014, Wybo Wiersma, available under the GPL v3
# This model builds upon Epsteins model of protest, and illustrates
# the possible impact of social media on protest formation.

Function::property = (property) ->
  for key, value of property
    Object.defineProperty @prototype, key, value

class MM.Medium extends ABM.Model
  setup: ->
    @size = 0.6

    # Shape to bitmap for better performance.
    @agents.setUseSprites()

    @animator.setRate 20, false

    @dummyAgent = {twin: {active: false}, read: (->), dummy: true}

    for patch in @patches.create()
      patch.color = u.color.white

  createAgent: (twin) ->
    @agents.create 1
    agent = @agents.last()
    agent.twin = twin
    twin.twins[twin.model.config.medium] = agent

    agent.size = @size
    agent.heading = u.degreesToRadians(270)
    agent.color = twin.color

    agent.read = (message) ->
      @closeMessage()

      if message
        message.readers.push(@)

      @reading = message

    agent.closeMessage = ->
      if @reading?
        @reading.readers.remove(@)

      @reading = null

    return agent

  colorPatch: (patch, message) ->
    if message.active
      patch.color = u.color.pink
    else
      patch.color = u.color.lightgray

  resetPatches: ->
    for patch in @patches
      patch.color = u.color.white

class MM.Message
  constructor: (options) ->
    @from = options.from
    @to = options.to
    @active = options.active
    @readers = new ABM.Array
  
  destroy: ->
    for reader in @readers
      reader.die()

class MM.Agent extends ABM.Agent
  constructor: ->
    super

    @twins = new ABM.Array

  twin: ->
    @twins[@model.config.medium]

  setColor: (color) ->
    @color = new u.color color
    @sprite = null

  moveToRandomEmptyLocation: ->
    @moveTo(@model.patches.sample((patch) -> patch.empty()).position)

  randomEmptyNeighbor: ->
    @patch.neighbors(@vision).sample((patch) -> patch.empty())

class MM.Communication
  constructor: (model, options = {}) ->
    @model = model

    @media = new ABM.Array

    @media[MM.MEDIA.none] = new MM.None(@model.config.mediaModelOptions)
    @media[MM.MEDIA.forum] = new MM.Forum(@model.config.mediaModelOptions)
    @media[MM.MEDIA.website] = new MM.Website(@model.config.mediaModelOptions)
    @media[MM.MEDIA.email] = new MM.EMail(@model.config.mediaModelOptions)

    @updateOldMedium()

  medium: ->
    @media[@model.config.medium]

  oldMedium: ->
    @media[@model.config.oldMedium]

  updateOldMedium: ->
    @model.config.oldMedium = @model.config.medium

class MM.EMail extends MM.Medium
  setup: ->
    super

    @inboxes = new ABM.Array

  step: ->
    for agent in @agents
      if u.randomInt(3) == 1
        @newMail(agent)
      else
        agent.readMail()

    @drawAll()

  use: (twin) ->
    agent = @createAgent(twin)
    agent.inbox = @inboxes[agent.twin.id] = new ABM.Array
    agent.readMail = ->
      agent.read(@inbox.pop())

  newMail: (agent) ->
    @route new MM.Message from: agent, to: @agents.sample(),
      active: agent.twin.active

  route: (message) ->
    @inboxes[message.to.twin.id].push message

  drawAll: ->
    @resetPatches()

    x_offset = y_offset = 0
    for agent, i in @agents
      x = i % (@world.max.x + 1)
      y_offset = Math.floor(i / (@world.max.x + 1)) * 5

      for message, j in agent.inbox
        patch = @patches.patch(x: x, y: y_offset + j)
        @colorPatch(patch, message)

      agent.moveTo x: x, y: y_offset

class MM.Forum extends MM.Medium
  setup: ->
    super

    @threads = new ABM.Array

    @newThread(@dummyAgent)
    @dummyAgent.reading = @threads[0][0]

    while @threads.length <= @world.max.x
      @newPost(@dummyAgent)

  use: (twin) -> # TODO make super
    agent = @createAgent(twin)
    agent.read(@threads[0][0])

  step: ->
    for agent in @agents
      if agent # might have died already
        if u.randomInt(20) == 1
          @newPost(agent)

        @moveForward(agent)

    @drawAll()

  newPost: (agent) ->
    if u.randomInt(7) == 1
      @newThread(agent)
    else
      @newComment(agent)

  newThread: (agent) ->
    newThread = new ABM.Array
    
    newThread.next = @threads.first()
    if newThread.next?
      newThread.next.previous = newThread

    newThread.post = (post) ->
      post.previous = @last()
      if post.previous?
        post.previous.next = post

      post.thread = @

      @push(post)

    newThread.destroy = ->
      @previous.next = null

      for message in @
        message.destroy() # takes readers as well

    newThread.post new MM.Message from: agent, active: agent.twin.active

    @threads.unshift newThread
    
    if @threads.length > @world.max.x + 1
      thread = @threads.pop()
      thread.destroy()

  newComment: (agent) ->
    agent.reading.thread.post new MM.Message from: agent, active: agent.twin.active

  moveForward: (agent) ->
    reading = agent.reading

    if reading.next?
      agent.read(reading.next)
    else if reading.thread.next?
      agent.read(reading.thread.next.first())
    else
      agent.die()
    
  drawAll: ->
    @resetPatches()

    for thread, i in @threads
      for post, j in thread
        if i <= @world.max.x and j <= @world.max.y
          post.patch = @patches.patch x: i, y: @world.max.y - j
          @colorPatch(post.patch, post)
        else
          post.patch = null

    for agent in @agents
      if agent.reading.patch?
        agent.moveTo(agent.reading.patch.position)

class MM.None extends MM.Medium
  setup: ->
    super

  use: (twin) ->

  step: ->

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


class MM.Website extends MM.Medium
  setup: ->
    super

    @sites = new ABM.Array

    while @sites.length < 100
      @newPage(@dummyAgent)

  use: (twin) ->
    @createAgent(twin)

  step: ->
    for agent in @agents
      if u.randomInt(20) == 1
        @newPage(agent)

      @moveToRandomPage(agent)

    @drawAll()

  newPage: (agent) ->
    @sites.unshift new MM.Message from: agent, active: agent.twin.active
    @dropSite()

  dropSite: ->
    if @sites.length > 100
      site = @sites.pop()
      for reader in site.readers by -1
        @moveToRandomPage(reader)

  moveToRandomPage: (agent) ->
    agent.read(@sites.sample())

  drawAll: ->
    @resetPatches()

    for site in @sites
      if !site.patch?
        site.patch = @patches.sample()

      @colorPatch(site.patch, site) # TODO reduce

    for agent in @agents
      agent.moveTo(agent.reading.patch.position)

class MM.Model extends ABM.Model
  setup: ->
    @agentBreeds ["citizens", "cops"]
    @size = 0.9
    @vision = {diamond: 7} # Neumann 7

    for patch in @patches.create()
      if @config.type is MM.TYPES.enclave
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
        # Switch on effect test
        #if @twin()? and @twin().reading? and @twin().reading.active
        #  actives += 10
  
        for agent in @neighbors(@vision)
          if agent.breed.name is "cops"
            cops += 1
          else
            if @model.config.type is MM.TYPES.micro
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

        if @model.config.type is MM.TYPES.micro
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

          if @model.config.type is MM.TYPES.enclave
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

    unless @isHeadless
      window.modelUI.resetPlot()

  step: -> # called by MM.Model.animate
    @agents.shuffle()
    for agent in @agents
      agent.act()
      if u.randomInt(100) == 1
        if agent.breed.name is "citizens"
          @communication.medium().use(agent)

    unless @isHeadless
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

class MM.Initializer extends MM.Model
  @initialize: (@config) ->
    @config ?= new MM.Config
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
