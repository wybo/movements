@MM = MM = {}

if typeof ABM == 'undefined'
  code = require "./lib/agentbase.coffee"
  eval 'var ABM = this.ABM = code.ABM'

u = ABM.util # ABM.util alias
log = (object) -> console.log object

MM.TYPES = {normal: "0", enclave: "1", micro: "2"}
MM.MEDIA = {none: 0, email: "1", website: "2", forum: "3"}
MM.VIEWS = {none: 0, grievances: "1", arrest_probability: "2", net_risk: "3"}
# turn back to numbers once dat.gui fixed

class MM.Config
#  medium: MEDIA.none
#  medium: MEDIA.email
  medium: MM.MEDIA.forum
#  medium: MEDIA.website

  type: MM.TYPES.normal

  view: MM.VIEWS.net_risk

  citizenDensity: 0.7
  #copDensity: 0.02
  copDensity: 0.012
  maxPrisonSentence: 30
  regimeLegitimacy: 0.32
  threshold: 0.1
  thresholdMicro: 0.0
  vision: {diamond: 7} # Neumann 7
  kConstant: -2.3

  ui: {
    passives: {label: "Passives", color: "green"},
    actives: {label: "Actives", color: "red"},
    prisoners: {label: "Prisoners", color: "black"},
    cops: {label: "Cops", color: "blue"},
    media: {label: "Media", color: "black"}
    micros: {label: "Micros", color: "orange"},
  }

  # ### Do not modify below unless you know what you're doing.

  constructor: ->
    sharedModelOptions = {
      Agent: MM.Agent
      patchSize: 20
      mapSize: 20
      isTorus: true
    }

    @modelOptions = u.merge(sharedModelOptions, {
      div: "world"
      # config is added
    })

    @viewModelOptions = u.merge(sharedModelOptions, {
      div: "view"
    })

    @mediaModelOptions = {
      Agent: MM.Agent
      div: "medium"
      patchSize: 10
      min: {x: 0, y: 0}
      max: {x: 39, y: 39}
    }

    @config = @

  makeHeadless: ->
    @modelOptions.isHeadless = @mediaModelOptions.isHeadless = true

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

    @mediumMirrors = new ABM.Array # TODO move to model
    @viewMirrors = new ABM.Array # TODO move to model

  mediumMirror: ->
    @mediumMirrors[@model.config.medium]

  setColor: (color) ->
    @color = new u.color color
    @sprite = null

  moveToRandomEmptyLocation: ->
    @moveTo(@model.patches.sample((patch) -> patch.empty()).position)

  randomEmptyNeighbor: ->
    @patch.neighbors(@vision).sample((patch) -> patch.empty())

class MM.Media
  constructor: (model, options = {}) ->
    @model = model

    @media = new ABM.Array

    @media[MM.MEDIA.none] = new MM.MediumNone(@model.config.mediaModelOptions)
    @media[MM.MEDIA.forum] = new MM.MediumForum(@model.config.mediaModelOptions)
    @media[MM.MEDIA.website] = new MM.MediumWebsite(@model.config.mediaModelOptions)
    @media[MM.MEDIA.email] = new MM.MediumEMail(@model.config.mediaModelOptions)

    @updateOld()

  current: ->
    @media[@model.config.medium]

  old: ->
    @media[@model.config.oldMedium]

  updateOld: ->
    @model.config.oldMedium = @model.config.medium

# Copyright 2014, Wybo Wiersma, available under the GPL v3
# This model builds upon Epsteins model of protest, and illustrates
# the possible impact of social media on protest formation.

Function::property = (property) ->
  for key, value of property
    Object.defineProperty @prototype, key, value

class MM.Medium extends ABM.Model
  setup: ->
    @size = 0.6

    @dummyAgent = {original: {active: false}, read: (->), dummy: true}

    for patch in @patches.create()
      patch.color = u.color.white

  createAgent: (original) ->
    if !original.mediumMirror()
      @agents.create 1
      agent = @agents.last()
      agent.original = original
      original.mediumMirrors[original.model.config.medium] = agent

      agent.size = @size
      agent.heading = u.degreesToRadians(270)
      agent.color = original.color

      agent.read = (message) ->
        @closeMessage()

        if message
          message.readers.push(@)

        @reading = message

      agent.closeMessage = ->
        if @reading?
          @reading.readers.remove(@)

        @reading = null

    return original.mediumMirror()

  colorPatch: (patch, message) ->
    if message.active
      patch.color = u.color.pink
    else
      patch.color = u.color.lightgray

  resetPatches: ->
    for patch in @patches
      patch.color = u.color.white

  copyOriginalColors: ->
    for agent in @agents
      agent.color = agent.original.color

class MM.MediumEMail extends MM.Medium
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

  use: (original) ->
    agent = @createAgent(original)
    agent.inbox = @inboxes[agent.original.id] = new ABM.Array
    agent.readMail = ->
      agent.read(@inbox.pop())

  newMail: (agent) ->
    @route new MM.Message {
      from: agent, to: @agents.sample(), active: agent.original.active
    }

  route: (message) ->
    @inboxes[message.to.original.id].push message

  drawAll: ->
    @copyOriginalColors()
    @resetPatches()

    x_offset = y_offset = 0
    for agent, i in @agents
      x = i % (@world.max.x + 1)
      y_offset = Math.floor(i / (@world.max.x + 1)) * 5

      for message, j in agent.inbox
        patch = @patches.patch(x: x, y: y_offset + j)
        @colorPatch(patch, message)

      agent.moveTo x: x, y: y_offset

class MM.MediumForum extends MM.Medium
  setup: ->
    super

    @threads = new ABM.Array

    @newThread(@dummyAgent)
    @dummyAgent.reading = @threads[0][0]

    while @threads.length <= @world.max.x
      @newPost(@dummyAgent)

  use: (original) -> # TODO make super
    agent = @createAgent(original)
    agent.read(@threads[0][0])

  step: ->
    for agent in @agents
      if agent # might have died already TODO check this, should not!
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

    newThread.post new MM.Message from: agent, active: agent.original.active

    @threads.unshift newThread
    
    if @threads.length > @world.max.x + 1
      thread = @threads.pop()
      thread.destroy()

  newComment: (agent) ->
    agent.reading.thread.post new MM.Message from: agent, active: agent.original.active

  moveForward: (agent) ->
    reading = agent.reading

    if reading.next?
      agent.read(reading.next)
    else if reading.thread.next?
      agent.read(reading.thread.next.first())
    else
      agent.die()
    
  drawAll: ->
    @copyOriginalColors()
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

class MM.MediumNone extends MM.Medium
  setup: ->
    super

  use: (original) ->

  step: ->

class MM.MediumWebsite extends MM.Medium
  setup: ->
    super

    @sites = new ABM.Array

    while @sites.length < 100
      @newPage(@dummyAgent)

  use: (original) ->
    @createAgent(original)

  step: ->
    for agent in @agents
      if u.randomInt(20) == 1
        @newPage(agent)

      @moveToRandomPage(agent)

    @drawAll()

  newPage: (agent) ->
    @sites.unshift new MM.Message from: agent, active: agent.original.active
    @dropSite()

  dropSite: ->
    if @sites.length > 100
      site = @sites.pop()
      for reader, index in site.readers by -1
        @moveToRandomPage(reader)

  moveToRandomPage: (agent) ->
    agent.read(@sites.sample())

  drawAll: ->
    @copyOriginalColors()
    @resetPatches()

    for site in @sites
      if !site.patch?
        site.patch = @patches.sample()

      @colorPatch(site.patch, site) # TODO reduce

    for agent in @agents
      agent.moveTo(agent.reading.patch.position)

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
      view: [MM.VIEWS]
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
        if key == "view"
          adder = @gui.add(@model.config, key, value...)
          adder.onChange((newView) =>
            @model.views.old().reset()
            @model.views.current().restart()
            @model.views.current().populate(@model)
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
    @model.resetData()
    @plotRioters = []
    for key, variable of @model.config.ui
      @plotRioters.push({
        label: variable.label, color: variable.color, data: @model.data[key]
      })

    @plotter = $.plot(@plotDiv, @plotRioters, @plotOptions)
    @drawPlot()

  drawPlot: ->
    @plotter.setData(@plotRioters)
    @plotter.setupGrid()
    @plotter.draw()

  addMediaMarker: ->
    @mediaMarker = true
    console.log "Adding MEDIA MARKER"

# Copyright 2014, Wybo Wiersma, available under the GPL v3
# This model builds upon Epsteins model of protest, and illustrates
# the possible impact of social media on protest formation.

class MM.View extends ABM.Model
  setup: ->
    for patch in @patches.create()
      patch.color = u.color.white

  populate: (model) ->
    for original in model.agents
      @createAgent(original)

  step: ->
    for agent in @agents
      if agent.original.position
        agent.moveTo agent.original.position
      else
        agent.moveOff()

  createAgent: (original) ->
    @agents.create 1
    agent = @agents.last()
    agent.original = original
    original.viewMirrors[original.model.config.view] = agent

    agent.size = @size
    agent.shape = "square"

class MM.ViewArrestProbability extends MM.View
  setup: ->
    @size = 1.0
    super

  populate: (options) ->
    super(options)

    for agent in @agents
      if agent.original.breed.name is "cops"
        agent.color = agent.original.color

  step: ->
    super

    for agent in @agents
      if agent.original.breed.name is "citizens"
        agent.color = u.color.red.fraction(agent.original.arrestProbability())

class MM.ViewGrievance extends MM.View
  setup: ->
    @size = 1.0
    super

  populate: (options) ->
    super(options)

    for agent in @agents
      if agent.original.breed.name is "citizens"
        agent.color = u.color.red.fraction(agent.original.grievance())
      else
        agent.color = agent.original.color

  step: ->
    super

class MM.ViewNetRisk extends MM.View
  setup: ->
    @size = 1.0
    super

  populate: (options) ->
    super(options)

    for agent in @agents
      if agent.original.breed.name is "cops"
        agent.color = agent.original.color

  step: ->
    super

    for agent in @agents
      if agent.original.breed.name is "citizens"
        agent.color = u.color.red.fraction(agent.original.netRisk())

class MM.Views
  constructor: (model, options = {}) ->
    @model = model

    @views = new ABM.Array

    @views[MM.VIEWS.grievances] = new MM.ViewGrievance(@model.config.viewModelOptions)
    @views[MM.VIEWS.arrest_probability] = new MM.ViewArrestProbability(@model.config.viewModelOptions)
    @views[MM.VIEWS.net_risk] = new MM.ViewNetRisk(@model.config.viewModelOptions)

    @updateOld()

  current: ->
    @views[@model.config.view]

  old: ->
    @views[@model.config.oldView]

  updateOld: ->
    @model.config.oldView = @model.config.view

class MM.Model extends ABM.Model
  setup: ->
    @agentBreeds ["citizens", "cops"]
    @size = 0.9
    @resetData()

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
      citizen.config = @config
      citizen.size = @size
      citizen.shape = "person"
      citizen.setColor "green"
      citizen.moveToRandomEmptyLocation()

      citizen.hardship = u.randomFloat()
      citizen.riskAversion = u.randomFloat()
      citizen.active = false
      citizen.activeMicro = 0.0
      citizen.prisonSentence = 0

      citizen.grievance = ->
        @hardship * (1 - @config.regimeLegitimacy)

      citizen.arrestProbability = ->
        cops = 0
        actives = 1
        # Switch on effect test
        #if @mediumMirror()? and @mediumMirror().reading? and @mediumMirror().reading.active
        #  actives += 10
  
        for agent in @neighbors(@config.vision)
          if agent.breed.name is "cops"
            cops += 1
          else
            if @model.config.type is MM.TYPES.micro
              if agent.breed.name is "citizen"
                actives += agent.activeMicro
            else
              if agent.breed.name is "citizen" and agent.active
                actives += 1

        @calculateArrestProbability(cops, actives)

      citizen.calculateArrestProbability = (cops, actives) ->
        1 - Math.exp(@config.kConstant * cops / actives)

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
          if activation > @config.threshold
            @active = true
            @setColor "red"
            @activeMicro = 1.0
          else if activation > @config.thresholdMicro
            @active = false
            @setColor "orange"
            @activeMicro = 0.4
          else
            @active = false
            @setColor "green"
            @activeMicro = 0.0
        else
          if activation > @config.threshold
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
      cop.config = @config
      cop.size = @size
      cop.shape = "person"
      cop.setColor "blue"
      cop.moveToRandomEmptyLocation()

      cop.makeArrest = ->
        protesters = 0
        passives = 0
        for agent in @neighbors(@config.vision)
          if agent.breed.name is "citizens" and agent.active
            protesters += 1
          else
            passives += 1

        protester = @neighbors(@config.vision).sample((agent) ->
          agent.breed.name is "citizens" and agent.active)
        if protester
          protester.imprison(1 + u.randomInt(@config.maxPrisonSentence))

      cop.act = ->
        empty = @randomEmptyNeighbor()
        @moveTo(empty.position) if empty
        @makeArrest()

    unless @isHeadless
      window.modelUI.resetPlot()

    unless @isHeadless
      @views.current().populate(@)
      @consoleLog()

  step: -> # called by MM.Model.animate
    @agents.shuffle()
    for agent in @agents
      agent.act()
      if u.randomInt(100) == 1
        if agent.breed.name is "citizens"
          @media.current().use(agent)

    unless @isHeadless
      window.modelUI.drawPlot()

    @media.current().once()
    @views.current().once()

    @recordData()

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

  tickData: ->
    citizens = @citizens.length
    actives = @actives().length
    micros = @micros().length
    prisoners = @prisoners().length

    return {
      citizens: citizens
      actives: actives
      micros: micros
      prisoners: prisoners
      passives: citizens - actives - micros - prisoners
      cops: @cops.length
    }

  resetData: ->
    @data = {
      passives: [], actives: [], prisoners: [], cops: [], micros: [],
      media: []
    }
    
  recordData: ->
    ticks = @animator.ticks
    tickData = @tickData()

    @data.passives.push [ticks, tickData.passives]
    @data.actives.push [ticks, tickData.actives]
    @data.prisoners.push [ticks, tickData.prisoners]
    @data.cops.push [ticks, tickData.cops]
    @data.micros.push [ticks, tickData.micros]

  recordMediaChange: ->
    @data.media.push [ticks, 0], [ticks, @citizens.length], null

  consoleLog: ->
    console.log 'Config:'
    console.log @config
    console.log 'Calibration:'
    console.log '  Arrest Probability:'
    for pair in [
        [0, 1],
        [1, 1], [2, 1], [3, 1], [4, 1]
        [1, 4], [2, 4], [3, 4], [4, 4]
      ]
      console.log @citizens[0].calculateArrestProbability(pair[0], pair[1])
    console.log 'Citizens:'
    console.log @citizens
    console.log 'Cops:'
    console.log @cops

class MM.Initializer extends MM.Model
  @initialize: (@config) ->
    @config ?= new MM.Config
    console.log @config
    return new MM.Initializer(u.merge(@config.modelOptions, {config: @config}))
    #return new MM.Initializer(@config) TODO
  
  startup: ->
    @media = new MM.Media(this)
    unless @isHeadless
      @views = new MM.Views(this)
      window.modelUI = new MM.UI(this)

  setup: ->
    @agents.setUseSprites() # Bitmap for better performance.
    @animator.setRate 20, false
    super()
