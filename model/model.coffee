# Copyright 2014, Wybo Wiersma, available under the GPL v3
# This model builds upon Epsteins model of protest, and illustrates
# the possible impact of social media on protest formation.

class MM.Model extends ABM.Model
  restart: ->
    @media.restart()

    unless @isHeadless
      @views.current().restart()

    super

  setup: ->
    @agentBreeds ["citizens", "cops"]
    @size = 0.9
    @resetData()

    for patch in @patches.create()
      @config.colorPatch(patch)

    space = @patches.length

    for citizen in @citizens.create @config.citizenDensity * space
      @setupCitizen(citizen)

    @config.resetAllFriends.call(@)

    for cop in @cops.create @config.copDensity * space
      @setupCop(cop)

    unless @isHeadless
      window.modelUI.resetPlot()
      @media.populate()
      @views.current().populate()
      @consoleLog()

  setupCitizen: (citizen) ->
    citizen.config = @config
    citizen.size = @size
    citizen.shape = "person"
    citizen.setColor "green"
    citizen.moveToRandomEmptyLocation()

    citizen.hardship = @config.hardshipDistribution() # H
    citizen.hardshipped = true if citizen.hardship > 0.5
    citizen.riskAversion = @config.riskAversionDistribution() # R
    citizen.riskAverse = true if citizen.riskAversion > 0.5
    citizen.lastLegitimacyDrop = 0
    citizen.active = false
    citizen.activism = 0.0
    citizen.arrestDuration = 0
    citizen.prisonSentence = 0
    citizen.sawArrest = false

    citizen.act = ->
      # TODO make media reading read a certain nr of posts!
      @mediaTickReset()

      if !@fighting()
        if @imprisoned()
          @prisonSentence -= 1

          if !@imprisoned()
            @moveToRandomEmptyLocation()

      if !@imprisoned() # free or just released
        @config.moveOffIfOnline.call(@)

        if @position? # free, just released, and not behind PC
          @config.move.call(@)
          @config.maintainFriends.call(@)

          if @config.holdOnlyIfNotified and @active and u.randomInt(20) == 1
            @leaveNotice()

          @activate()
          @updateColor()

    citizen.grievance = ->
      @hardship * (1 - @regimeLegitimacy())

    citizen.regimeLegitimacy = ->
      @config.regimeLegitimacy.call(@)

    citizen.arrestProbability = ->
      count = @countNeighbors(vision: @config.vision)

      count.activism += 1
      count.actives += 1
      count.citizens += 1

      if count.arrests > 0
        @sawArrest = true
      else
        @sawArrest = false

      @calculatePerceivedArrestProbability(count)

    citizen.netRisk = ->
      @arrestProbability() * @riskAversion

    citizen.imprison = ->
      @prisonSentence = 1 + u.randomInt(@config.maxPrisonSentence)
      @moveOff()
      @goOffline()

    citizen.arrest = ->
      @arrestDuration = @config.arrestDuration
      @setColor "purple"

    citizen.beatUp = ->
      @arrestDuration -= 1

    citizen.fighting = ->
      @arrestDuration > 0

    citizen.imprisoned = ->
      @prisonSentence > 0

    citizen.advance = ->
      @moveAwayFromArrestProbability(@config.walk, @config.vision)

    citizen.activate = ->
      if @config.holdActivation
        if @active or @model.animator.ticks % @config.holdInterval < @config.holdReleaseDuration and !@config.holdOnlyIfNotified or @notified
          @actuallyActivate()
          @notified = false
      else
        @actuallyActivate()

    citizen.actuallyActivate = ->
      activation = @grievance() - @netRisk()
      status = @calculateActiveStatus(activation)
      @config.setStatus.call(@, status)

    citizen.updateColor = ->
      if @active
        @setColor "red"
      else
        if @activism > 0
          @setColor "orange"
        else
          @setColor "green"

  setupCop: (cop) ->
    cop.config = @config
    cop.size = @size
    cop.shape = "person"
    cop.arresting = null
    cop.setColor "blue"
    cop.moveToRandomEmptyLocation()

    cop.act = ->
      if @fighting()
        @arresting.beatUp()
        if !@arresting.fighting()
          @arresting.imprison()
          @arresting = null

      if !@fighting()
        count = @countNeighbors(vision: @config.vision)
        count.cops += 1

        if @config.copsDefect and count.activism * 2 > count.citizens and count.cops * 10 < count.activism and @model.animator.ticks > 50
          patch = @patch
          @die()
          citizen = @model.citizens.create 1, (citizen) =>
            @model.setupCitizen(citizen)
            citizen.moveTo(patch.position)
        else if @config.copsRetreat and @calculateCopWillMakeArrestProbability(count) < u.randomFloat()
          @retreat()
        else if @model.prisoners().length < @config.prisonCapacity * @model.agents.length
          @initiateArrest()
          @moveToRandomEmptyNeighbor()

    cop.retreat = ->
      @moveTowardsArrestProbability(@config.walk, @config.vision, true)

    cop.initiateArrest = ->
      protester = @neighbors(@config.vision).sample(condition: (agent) ->
        agent.breed.name is "citizens" and
          agent.active and !agent.fighting())

      if protester
        @arresting = protester
        @arresting.arrest()

    cop.fighting = ->
      return (@arresting != null)

  step: -> # called by MM.Model.animate
    @agents.shuffle()
    for agent in @agents
      agent.act()
      if agent.breed.name is "citizens"
        for medium in @media.adopted
          if u.randomInt(20) == 1
            medium.access(agent)

    unless @isHeadless
      window.modelUI.drawPlot()

    @media.once()

    unless @isHeadless
      @views.current().once()

    @recordData()
    
    if @config.testRun
      @testStep()

  set: (key, value) ->
    if key == "medium"
      @config["media"] = [value]
    else
      @config[key] = value
    @config.check()
    @config.setFunctions()

    if key == "view"
      @views.changed()
    else if key == "friends"
      @config.resetAllFriends.call(@)
    else if key == "medium"
      @media.changed()
      # TODO update UI

  actives: ->
    actives = []
    for citizen in @citizens
      if citizen.active and not (citizen.fighting() or citizen.imprisoned())
        actives.push citizen
    return actives

  micros: ->
    micros = []
    @config.micros.call(@)
    return micros

  arrests: ->
    arrests = []
    for citizen in @citizens
      if citizen.fighting()
        arrests.push citizen
    return arrests

  prisoners: (reset = false) ->
    if !@prisonersCache or reset
      @prisonersCache = []
      for citizen in @citizens
        if citizen.imprisoned()
          @prisonersCache.push citizen
    return @prisonersCache

  onlines: (reset = false) ->
    if !@onlinesCache or reset
      @onlinesCache = []
      for citizen in @citizens
        if citizen.online()
          @onlinesCache.push citizen
    return @onlinesCache

  tickData: ->
    citizens = @citizens.length
    actives = @actives().length
    micros = @micros().length
    arrests = @arrests().length
    prisoners = @prisoners(true).length

    return {
      citizens: citizens
      passives: citizens - actives - micros - arrests - prisoners
      actives: actives
      micros: micros
      arrests: arrests
      prisoners: prisoners
      cops: @cops.length
      onlines: @onlines(true).length
    }

  resetData: ->
    @data = {
      passives: [],
      actives: [],
      micros: [],
      arrests: [],
      prisoners: [],
      cops: [],
      onlines: [],
      media: []
    }
    
  recordData: ->
    ticks = @animator.ticks
    tickData = @tickData()

    @data.passives.push [ticks, tickData.passives]
    @data.actives.push [ticks, tickData.actives]
    @data.micros.push [ticks, tickData.micros]
    @data.arrests.push [ticks, tickData.arrests]
    @data.prisoners.push [ticks, tickData.prisoners]
    @data.cops.push [ticks, tickData.cops]
    @data.onlines.push [ticks, tickData.onlines]

  recordMediaChange: ->
    ticks = @animator.ticks
    @data.media.push {ticks: ticks, medium: @config.oldMedium, state: false}
    @data.media.push {ticks: ticks, medium: @config.medium, state: true}
    unless @isHeadless
      window.modelUI.plotOptions.grid.markings.push { color: "#000", lineWidth: 1, xaxis: { from: ticks, to: ticks } }

  consoleLog: ->
    console.log 'Config:'
    console.log @config
    console.log 'Calibration:'
    console.log '  Arrest Probability:'

    for count in [
        {cops: 0, activism: 1},
        {cops: 1, activism: 1}, {cops: 2, activism: 1}, {cops: 3, activism: 1},
        {cops: 1, activism: 4}, {cops: 2, activism: 4}, {cops: 3, activism: 4}
      ]
      console.log @citizens[0].calculatePerceivedArrestProbability(count)

    console.log 'Citizens:'
    console.log @citizens
    console.log 'Cops:'
    console.log @cops

  testSet: (key, hash, value) ->
    if key == "medium"
      @config["media"] = [value]
    else
      @config[key] = value
    console.log "Testing " + key + " " + u.deIndexHash(hash)[@config[key]]

  testAdvance: (key, hash) ->
    if @config[key] < Object.keys(hash).length - 1
      @testSet(key, hash, @config[key] + 1)
    else
      @testSet(key, hash, 0)

  testStep: ->
    if @animator.ticks % 2 == 0
      @testAdvance("calculation", MM.CALCULATIONS)
      if @config.calculation == 0
        @testAdvance("legitimacyCalculation", MM.LEGITIMACY_CALCULATIONS)

    if @animator.ticks % 20 == 0
      @testAdvance("view", MM.VIEWS)
      mediaKey = MM.MEDIA[u.deIndexHash(MM.VIEWS)[@config.view]]
      if mediaKey
        @testSet("medium", MM.MEDIA, mediaKey)
        if @config.medium == 0
          @testAdvance("mediumType", MM.MEDIUM_TYPES)
        @media.changed()
      else
        @testSet("medium", MM.MEDIA, MM.MEDIA[u.array.sample(Object.keys(MM.MEDIA))])
      @views.changed()

#    if @animator.ticks % 12 == 0 TODO, errors out
#      @testAdvance("friends", MM.FRIENDS)
#      @resetAllFriends()

    if @animator.ticks > 20 * Object.keys(MM.VIEWS).length * Object.keys(MM.MEDIUM_TYPES).length
      console.log 'Test completed!'
      @stop()
