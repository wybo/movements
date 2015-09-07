@MM = MM = {}

if typeof ABM == 'undefined'
  code = require "./lib/agentbase.coffee"
  eval 'var ABM = this.ABM = code.ABM'

u = ABM.util # ABM.util alias
log = (object) -> console.log object

indexHash = (array) ->
  hash = {}
  i = 0
  for key in array
    hash[key] = "#{i++}"

  return hash

MM.TYPES = indexHash(["normal", "enclave", "focal_point", "micro"])
MM.CALCULATIONS = indexHash(["epstein", "wilensky", "overpowered", "real"])
MM.MEDIA = indexHash(["none", "email", "website", "forum", "facebook_wall"])
MM.MEDIUM_TYPES = indexHash(["normal", "micro"])
MM.VIEWS = indexHash(["none", "risk_aversion", "hardship", "grievance", "arrest_probability", "net_risk", "follow"])
# turn back to numbers once dat.gui fixed

console.log MM.VIEWS

class MM.Config
  type: MM.TYPES.normal
  calculation: MM.CALCULATIONS.real
  medium: MM.MEDIA.facebook_wall
  medium_type: MM.MEDIUM_TYPES.micro
  view: MM.VIEWS.arrest_probability
  
  cops_retreat: true
  actives_advance: false
  excitement: true
  friends: 50

  citizenDensity: 0.7
  #copDensity: 0.04
  #copDensity: 0.012
  copDensity: 0.025
  maxPrisonSentence: 30 # J
  regimeLegitimacy: 0.82 # L
  threshold: 0.1
  thresholdMicro: 0.0
  #vision: {diamond: 7} # Neumann 7, v and v*
  vision: {radius: 7} # Neumann 7, v and v*
  walk: {radius: 2} # Neumann 7, v and v*
  kConstant: 2.3 # k

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
      #mapSize: 15
      #mapSize: 20
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
  constructor: (from, to) ->
    @from = from
    @to = to
    @active = @from.original.active
    @activism = @from.original.activism
    @readers = new ABM.Array
  
  destroy: ->
    for reader in @readers
      reader.die()

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
      agent.count = {posts: 0, activism: 0}

      agent.read = (message) ->
        @closeMessage()

        if message
          message.readers.push(@)
          @count.posts += 1
          @count.activism += message.activism

        @reading = message

      agent.closeMessage = ->
        if @reading?
          @reading.readers.remove(@)

        @reading = null

      agent.resetCount = ->
        @count = {posts: 0, activism: 0}

    return original.mediumMirror()

  colorPatch: (patch, message) ->
    if message.activism == 1.0
      patch.color = u.color.pink
    else if message.activism > 0
      patch.color = u.color.orange
    else
      patch.color = u.color.lightgray

  resetPatches: ->
    for patch in @patches
      patch.color = u.color.white

  copyOriginalColors: ->
    for agent in @agents
      agent.color = agent.original.color

class MM.MediumGenericDelivery extends MM.Medium
  setup: ->
    super

    @inboxes = new ABM.Array

  createAgent: (original) ->
    agent = super

    if !agent.inbox
      agent.inbox = @inboxes[agent.original.id] = new ABM.Array

    return agent

  newMessage: (from, to) ->
    @route new MM.Message from, to

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

class MM.Agent extends ABM.Agent
  constructor: ->
    super

    @mediumMirrors = new ABM.Array # TODO move to model
    @viewMirrors = new ABM.Array # TODO move to model

    @friends_hash = {}
    @friends = []

  mediumMirror: ->
    @mediumMirrors[@model.config.medium]

  viewMirror: ->
    @viewMirrors[@model.config.view]

  setColor: (color) ->
    @color = new u.color color
    @sprite = null

  #### Calculations and counting

  calculatePerceivedArrestProbability: (count) ->
    return @calculateCopWillMakeArrestProbability(count) *
      @calculateSpecificCitizenArrestProbability(count)

  calculateSpecificCitizenArrestProbability: (count) ->
    if MM.CALCULATIONS.epstein == @model.config.calculation or MM.CALCULATIONS.overpowered == @model.config.calculation
      return 1 - Math.exp(-1 * @config.kConstant * count.cops / count.actives)
    else if MM.CALCULATIONS.wilensky == @model.config.calculation
      return 1 - Math.exp(-1 * @config.kConstant * Math.floor(count.cops / count.actives))
    else # real
      if count.cops > count.actives
        return 1
      else
        return count.cops / count.actives

  calculateCopWillMakeArrestProbability: (count) ->
    if MM.CALCULATIONS.overpowered == @model.config.calculation
      if count.cops * 5 > count.actives
        return 1
      else
        return 0
    else if MM.CALCULATIONS.real == @model.config.calculation
      overwhelm = count.cops * 7 / count.actives
      if overwhelm > 1
        return 1
      else
        return overwhelm
    else
      return 1

  calculateExcitement: (count) ->
    return (count.actives / count.citizens) ** 2

  countNeighbours: (vision, patch) ->
    cops = 0
    actives = 0
    citizens = 0
    activism = 0

    if patch
      neighbors = patch.neighborAgents(vision)
    else
      neighbors = @neighbors(vision)

    for agent in neighbors
      if agent.breed.name is "cops"
        cops += 1
      else
        if @model.config.friends
          friends_multiplier = 2
        else
          friends_multiplier = 1

        citizens += friends_multiplier

        if agent.active
          actives += friends_multiplier

        activism += agent.activism * friends_multiplier

    return {cops: cops, citizens: citizens, actives: actives, activism: activism}

  #### Movement

  moveTowardsPoint: (walk, point, towards = true) ->
    empties = @randomEmptyNeighbors(walk)
    toEmpty = empties.pop()
    lowestDistance = toEmpty.distance(point) if toEmpty
    for empty in empties
      distance = empty.distance(point)
      if (distance < lowestDistance and towards) or
          (distance > lowestDistance and !towards)
        lowestDistance = distance
        toEmpty = empty
    
    @moveTo(toEmpty.position) if toEmpty

  moveAwayFromPoint: (walk, point) ->
    @moveTowardsPoint(walk, point, false)

  # Assumes a world with an y-axis that runs from -X to X
  moveToRandomUpperHalf: (walk, upper = true) ->
    empties = @randomEmptyNeighbors(walk)

    # Already up there
    if upper and @position.y > 0
      toEmpty = empties.sample((o) -> o.position.y > 0)
    else if !upper and @position.y <= 0
      toEmpty = empties.sample((o) -> o.position.y <= 0)
    else
      toEmpty = null
      if upper
        mostVertical = @model.world.minCoordinate.y
      else
        mostVertical = @model.world.maxCoordinate.y

      for empty in empties
        vertical = empty.position.y

        # Edge up
        if (vertical > mostVertical and upper) or
            (vertical < mostVertical and !upper)
          mostVertical = vertical
          toEmpty = empty
    
    @moveTo(toEmpty.position) if toEmpty

  moveToRandomBottomHalf: (walk) ->
    @moveToRandomUpperHalf(walk, false)

  moveTowardsArrestProbability: (walk, vision, highest = true) ->
    empties = @randomEmptyNeighbors(walk)
    toEmpty = empties.pop()
    mostArrest = @calculatePerceivedArrestProbability(@countNeighbours(vision, toEmpty)) if toEmpty
    for empty in empties
      arrest = @calculatePerceivedArrestProbability(@countNeighbours(vision, empty))
      if (arrest > mostArrest and highest) or
          (arrest < mostArrest and !highest)
        mostArrest = arrest
        toEmpty = empty
    
    @moveTo(toEmpty.position) if toEmpty

  moveAwayFromArrestProbability: (walk, vision) ->
    @moveTowardsArrestProbability(walk, vision, false)

  moveToRandomEmptyLocation: ->
    @moveTo(@model.patches.sample((patch) -> patch.empty()).position)

  moveToRandomEmptyNeighbor: (walk) ->
    empty = @randomEmptyNeighbor(walk)

    if empty
      @moveTo(empty.position)

  randomEmptyNeighbor: (walk) ->
    @patch.neighbors(walk).sample((patch) -> patch.empty())

  randomEmptyNeighbors: (walk) ->
    @patch.neighbors(walk).select((patch) -> patch.empty()).shuffle()

  #### Misc

  isFriendsWith: (citizen) ->
    @friends_hash[citizen.id]

  makeRandomFriends: (number) ->
    needed = number - @friends.length # friends already made by others
    id = @id # taken into closure
    friends = @model.citizens.sample(needed, (o) ->
      o.friends.length < number and id != o.id
    )

    for friend in friends
      @friends.push friend
      friend.friends.push @
      @friends_hash[friend.id] = true
      friend.friends_hash[@id] = true

class MM.Media
  constructor: (model, options = {}) ->
    @model = model

    @media = new ABM.Array

    @media[MM.MEDIA.none] = new MM.MediumNone(@model.config.mediaModelOptions)
    @media[MM.MEDIA.email] = new MM.MediumEMail(@model.config.mediaModelOptions)
    @media[MM.MEDIA.website] = new MM.MediumWebsite(@model.config.mediaModelOptions)
    @media[MM.MEDIA.forum] = new MM.MediumForum(@model.config.mediaModelOptions)
    @media[MM.MEDIA.facebook_wall] = new MM.MediumFacebookWall(@model.config.mediaModelOptions)

    @updateOld()

  current: ->
    @media[@model.config.medium]

  old: ->
    @media[@model.config.oldMedium]

  updateOld: ->
    @model.config.oldMedium = @model.config.medium

class MM.MediumEMail extends MM.MediumGenericDelivery
  setup: ->
    super

  step: ->
    for agent in @agents
      if u.randomInt(3) == 1
        @newMessage(agent, @agents.sample())
      else
        agent.readMail()

    @drawAll()

  use: (original) ->
    agent = @createAgent(original)
    agent.readMail = ->
      agent.read(@inbox.pop())

class MM.MediumFacebookWall extends MM.MediumGenericDelivery
  setup: ->
    super

  step: ->
    for agent in @agents
      if u.randomInt(3) == 1
        @newPost(agent)
      else
        agent.readPosts()

    @drawAll()

  use: (original) ->
    agent = @createAgent(original)
    agent.readPosts = ->
      for post in @inbox
        agent.read(post)

      @inbox.clear()

  newPost: (agent) ->
    friends = @agents.sample(30, (o) ->
      agent.original.isFriendsWith(o.original)
    )

    for friend in friends
      @newMessage(agent, friend)

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

    newThread.post new MM.Message agent

    @threads.unshift newThread
    
    if @threads.length > @world.max.x + 1
      thread = @threads.pop()
      thread.destroy()

  newComment: (agent) ->
    agent.reading.thread.post new MM.Message agent

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
    @sites.unshift new MM.Message agent
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

  setupControls: () ->
    settings =
      type: [MM.TYPES]
      calculation: [MM.CALCULATIONS]
      medium: [MM.MEDIA]
      medium_type: [MM.MEDIUM_TYPES]
      view: [MM.VIEWS]
      #medium: [MM.MEDIA], {onChange: 55}
      citizenDensity: {min: 0, max: 1}
      copDensity: {min: 0, max: 0.10}
      maxPrisonSentence: {min: 0, max: 1000}
      regimeLegitimacy: {min: 0, max: 1}
      threshold: {min: -1, max: 1}
      thresholdMicro: {min: -1, max: 1}
      cops_retreat: null
      actives_advance: null
      excitement: null
      friends: null

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

# Copyright 2014, Wybo Wiersma, available under the GPL v3
# This model builds upon Epsteins model of protest, and illustrates
# the possible impact of social media on protest formation.

class MM.View extends ABM.Model
  setup: ->
    @agentBreeds ["citizens", "cops"]

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
    if original.breed.name == "citizens"
      @citizens.create 1
    else
      @cops.create 1

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

class MM.ViewFollow extends MM.View
  setup: ->
    @size = 1.0
    super

  populate: (model) ->
    super(model)

    @agent = model.citizens.first().viewMirror()

    console.log "Selected agent for following:"
    console.log @agent

  step: ->
    super

    for agent in @agents
      agent.color = u.color.white

    for agent in @agent.neighbors(@agent.original.config.vision)
      agent.color = agent.original.color

    @agent.original.color = @agent.color = u.color.black

class MM.ViewGeneric extends MM.View
  setup: ->
    @size = 1.0
    super

  populate: (options) ->
    super(options)

    for citizen in @citizens
      if MM.VIEWS.hardship == @config.view
        citizen.color = u.color.red.fraction(citizen.original.hardship)
      else if MM.VIEWS.risk_aversion == @config.view
        citizen.color = u.color.red.fraction(citizen.original.riskAversion)
      else if MM.VIEWS.grievance == @config.view
        citizen.color = u.color.red.fraction(citizen.original.grievance())

    for cop in @cops
      cop.color = cop.original.color

  step: ->
    super

    if MM.VIEWS.arrest_probability == @config.view
      for citizen in @citizens
        citizen.color = u.color.red.fraction(citizen.original.arrestProbability())
    else if MM.VIEWS.net_risk == @config.view
      for citizen in @citizens
        citizen.color = u.color.red.fraction(citizen.original.netRisk())

class MM.ViewNone extends MM.View
  setup: ->
    super

  populate: (options) ->

  step: ->

class MM.Views
  constructor: (model, options = {}) ->
    @model = model

    @views = new ABM.Array

    genericView = new MM.ViewGeneric(u.merge(@model.config.viewModelOptions, {config: @model.config}))

    for key, viewNumber of MM.VIEWS
      @views[viewNumber] = genericView

    @views[MM.VIEWS.none] = new MM.ViewNone(@model.config.viewModelOptions)
    @views[MM.VIEWS.follow] = new MM.ViewFollow(@model.config.viewModelOptions)

    console.log @views

    @updateOld()

  current: ->
    @views[@model.config.view]

  old: ->
    @views[@model.config.oldView]

  updateOld: ->
    @model.config.oldView = @model.config.view

class MM.Model extends ABM.Model
  restart: ->
    @media.current().restart()

    unless @isHeadless
      @views.current().restart()

    super

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

      citizen.hardship = u.randomFloat() # H
      citizen.riskAversion = u.randomFloat() # R
      citizen.active = false
      citizen.activism = 0.0
      citizen.prisonSentence = 0

      citizen.act = ->
        if @imprisoned()
          @prisonSentence -= 1

          if !@imprisoned() # just released
            @moveToRandomEmptyLocation()

        if !@imprisoned() # just released included
          if MM.TYPES.enclave == @model.config.type
            if @riskAversion < 0.5
              @moveToRandomUpperHalf(@config.walk)
            else
              @moveToRandomBottomHalf(@config.walk)
          else if MM.TYPES.focal_point == @model.config.type
            if @riskAversion < 0.5
              @moveTowardsPoint(@config.walk, {x: 0, y: 0})
            else
              @moveAwayFromPoint(@config.walk, {x: 0, y: 0})
          else
            if @config.actives_advance and @active
              @advance()
            else
              @moveToRandomEmptyNeighbor(@config.walk)

          @activate()

      citizen.grievance = ->
        @hardship * (1 - @config.regimeLegitimacy)

      citizen.arrestProbability = ->
        count = @countNeighbours(@config.vision)
  
        if MM.TYPES.micro == @config.type
          count.actives = count.activism

        count.actives += 1
        count.citizens += 1

        if MM.MEDIA.none != @config.medium and @mediumMirror()
          medium_count = @mediumMirror().count

          if MM.MEDIUM_TYPES.micro == @config.medium_type
            count.actives += medium_count.activism
          else
            count.actives += medium_count.actives

          count.citizens += medium_count.posts
          @mediumMirror().resetCount()

        @calculatePerceivedArrestProbability(count)

      citizen.excitement = ->
        count = @countNeighbours(@config.vision)
       
        if MM.TYPES.micro == @config.type
          count.actives = count.activism

        count.actives += 1
        count.citizens += 1

        @calculateExcitement(count)

      citizen.netRisk = ->
        @arrestProbability() * @riskAversion

      citizen.imprison = (sentence) ->
        @prisonSentence = sentence
        @moveOff()

      citizen.imprisoned = ->
        @prisonSentence > 0

      citizen.advance = ->
        @moveAwayFromArrestProbability(@config.walk, @config.vision)

      citizen.activate = ->
        activation = @grievance() - @netRisk()
        if @config.excitement
          if activation < 1
            activation += @excitement() * 0.2
        #activation = @grievance() - @netRisk()

        if activation > @config.threshold
          @active = true
          @activism = 1.0
          @setColor "red"
        else
          @active = false
          if activation > @config.thresholdMicro
            @activism = 0.4

            if MM.TYPES.micro == @model.config.type
              @setColor "orange"
            else
              @setColor "green"
          else
            @activism = 0.0
            @setColor "green"

    if @config.friends
      for citizen in @citizens
        citizen.makeRandomFriends(@config.friends)

    for cop in @cops.create @config.copDensity * space
      cop.config = @config
      cop.size = @size
      cop.shape = "person"
      cop.setColor "blue"
      cop.moveToRandomEmptyLocation()

      cop.act = ->
        count = @countNeighbours(@config.vision)
        count.cops += 1

        if @calculateCopWillMakeArrestProbability(count) > u.randomFloat()
          @makeArrest()
          @moveToRandomEmptyNeighbor()
        else
          if @config.cops_retreat
            @retreat()
          else
            @moveToRandomEmptyNeighbor()

      cop.retreat = ->
        @moveTowardsArrestProbability(@config.walk, @config.vision, true)

      cop.makeArrest = ->
          protester = @neighbors(@config.vision).sample((agent) ->
            agent.breed.name is "citizens" and agent.active)

          if protester
            protester.imprison(1 + u.randomInt(@config.maxPrisonSentence))

    unless @isHeadless
      window.modelUI.resetPlot()
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

    unless @isHeadless
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
      if !citizen.active and citizen.activism > 0 and
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

    #@data.passives.push [ticks, tickData.passives]
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

    for count in [
        {cops: 0, actives: 1},
        {cops: 1, actives: 1}, {cops: 2, actives: 1}, {cops: 3, actives: 1},
        {cops: 1, actives: 4}, {cops: 2, actives: 4}, {cops: 3, actives: 4}
      ]
      console.log @citizens[0].calculatePerceivedArrestProbability(count)

    console.log 'Citizens:'
    console.log @citizens
    console.log 'Cops:'
    console.log @cops

class MM.ModelSimple extends ABM.Model
  restart: ->
    @media.current().restart()

    unless @isHeadless
      @views.current().restart()

    super

  setup: ->
    @agentBreeds ["citizens", "cops"]
    @size = 0.9
    @resetData()

    for patch in @patches.create()
      patch.color = u.color.random type: "gray", min: 224, max: 255

    space = @patches.length

    for citizen in @citizens.create @config.citizenDensity * space
      citizen.config = @config
      citizen.size = @size
      citizen.shape = "person"
      citizen.setColor "green"
      citizen.moveToRandomEmptyLocation()

      citizen.hardship = u.randomFloat() # H
      citizen.active = false
      citizen.prisonSentence = 0

      citizen.act = ->
        if @imprisoned()
          @prisonSentence -= 1

          if !@imprisoned() # just released
             @moveToRandomEmptyLocation()

        if !@imprisoned()
          @moveToRandomEmptyNeighbor(@config.walk)
          @activate()

      citizen.excitement = ->
        count = @countNeighbours(@config.vision)
        count.actives += 1

        @calculateExcitement(count)

      citizen.activate = ->
        if @excitement() > @hardship
          @active = true
          @setColor "red"
        else
          @active = false
          @setColor "green"

       citizen.imprison = (sentence) ->
         @prisonSentence = sentence
         @moveOff()

       citizen.imprisoned = ->
         @prisonSentence > 0

     for cop in @cops.create @config.copDensity * space
       cop.config = @config
       cop.size = @size
       cop.shape = "person"
       cop.setColor "blue"
       cop.moveToRandomEmptyLocation()

       cop.act = ->
         @makeArrest()
         @moveToRandomEmptyNeighbor()

       cop.makeArrest = ->
          protester = @neighbors(@config.vision).sample((agent) ->
            agent.breed.name is "citizens" and agent.active)

          if protester
            protester.imprison(1 + u.randomInt(@config.maxPrisonSentence))

    unless @isHeadless
      window.modelUI.resetPlot()
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

    unless @isHeadless
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
      if citizen.active
        actives.push citizen
    actives

  micros: ->
    []

  cops: ->
    @cops.length

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

    #@data.passives.push [ticks, tickData.passives]
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

    for count in [
        {cops: 0, actives: 1},
        {cops: 1, actives: 1}, {cops: 2, actives: 1}, {cops: 3, actives: 1},
        {cops: 1, actives: 4}, {cops: 2, actives: 4}, {cops: 3, actives: 4}
      ]
      console.log @citizens[0].calculatePerceivedArrestProbability(count)

    console.log 'Citizens:'
    console.log @citizens
    console.log 'Cops:'
    console.log @cops

#class MM.Initializer extends MM.ModelSimple
class MM.Initializer extends MM.Model
  @initialize: (@config) ->
    @config ?= new MM.Config
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
