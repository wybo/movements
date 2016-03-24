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
      if MM.TYPES.enclave == @config.type
        if patch.position.y > 0
          patch.color = u.color.random type: "gray", min: 180, max: 204
        else
          patch.color = u.color.random type: "gray", min: 234, max: 255
      else
        patch.color = u.color.random type: "gray", min: 224, max: 255

    space = @patches.length

    for citizen in @citizens.create @config.citizenDensity * space
      @setupCitizen(citizen)

    @resetAllFriends()

    for cop in @cops.create @config.copDensity * space
      @setupCop(cop)

    unless @isHeadless
      window.modelUI.resetPlot()
      @views.current().populate(@)
      @consoleLog()

  setupCitizen: (citizen) ->
    citizen.config = @config
    citizen.size = @size
    citizen.shape = "person"
    citizen.setColor "green"
    citizen.moveToRandomEmptyLocation()

    citizen.hardship = u.randomFloat() # H
    citizen.hardship = u.clamp(u.randomNormal(0.5, 0.5 / 3), 0, 1) # H
    citizen.hardshipped = true if citizen.hardship > 0.5
    citizen.riskAversion = u.clamp(u.randomNormal(0.5, 0.5 / 3), 0, 1) # R
    citizen.riskAversion = u.randomFloat() # R
    citizen.riskAverse = true if citizen.riskAversion > 0.5
    citizen.lastLegitimacyDrop = 0
    citizen.active = false
    citizen.activism = 0.0
    citizen.arrestDuration = 0
    citizen.prisonSentence = 0
    citizen.sawArrest = false

    citizen.act = ->
      if !@fighting()
        if @imprisoned()
          @prisonSentence -= 1

          if !@imprisoned()
            @moveToRandomEmptyLocation()

        if @mediumMirror()
          @mediumMirror().resetCount()
          
          if !@imprisoned()
            if !@config.smartPhones and @mediumMirror().online() and @position
              @moveOff()
            else if !@position
              @moveToRandomEmptyLocation()
        
        if @position? # free, just released, and not behind PC
          if MM.TYPES.enclave == @config.type
            if @riskAverse
              @moveToRandomBottomHalf(@config.walk)
            else
              @moveToRandomUpperHalf(@config.walk)
          else if MM.TYPES.focalPoint == @config.type
            if @riskAverse
              @moveAwayFromPoint(@config.walk, {x: 0, y: 0})
            else
              @moveTowardsPoint(@config.walk, {x: 0, y: 0})
          else if MM.TYPES.square == @config.type
            @moveToRandomEmptyNeighbor(@config.walk)
            if @active
              @swapToActiveSquare({x: 0, y: 0}, range: 5)
          else
            if @config.activesAdvance and @active
              @advance()
            else
              @moveToRandomEmptyNeighbor(@config.walk)

          if MM.FRIENDS.local == @config.friends
            @makeLocalFriends(@config.friendsNumber)

          if @config.holdOnlyIfNotified and @active and u.randomInt(20) == 1
            @leaveNotice()

          @activate()
          @updateColor()

    citizen.grievance = ->
      @hardship * (1 - @regimeLegitimacy())

    citizen.regimeLegitimacy = ->
      if MM.LEGITIMACY_CALCULATIONS.base == @config.legitimacyCalculation or @imprisoned()
        return @config.baseRegimeLegitimacy
      else
        if @mediumMirror() and @mediumMirror().online()
          count = @mediumMirror().count

          count.citizens = count.reads # TODO fix/simplify
        else
          count = @countNeighbors(vision: @config.vision)

        @lastLegitimacyDrop = (@lastLegitimacyDrop * 2 + @calculateLegitimacyDrop(count)) / 3

        return @config.baseRegimeLegitimacy - @lastLegitimacyDrop * 0.1

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
      if MM.TYPES.hold == @config.type
        if @active or @model.animator.ticks % @config.holdInterval < @config.holdReleaseDuration and !@config.holdOnlyIfNotified or @notified
          @actuallyActivate()
          @notified = false
      else
        @actuallyActivate()

    citizen.actuallyActivate = ->
      activation = @grievance() - @netRisk()
      status = @calculateActiveStatus(activation)
      @active = status.active
      @micro = status.micro
      if MM.TYPES.micro == @config.type
        @activism = status.micro
      else
        @activism = status.activism

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
      if agent.breed.name is "citizens" and u.randomInt(20) == 1
          @media.current().use(agent)

    unless @isHeadless
      window.modelUI.drawPlot()

    @media.current().once()

    unless @isHeadless
      @views.current().once()

    @recordData()
    
    if @config.testRun
      @testStep()

  resetAllFriends: ->
    if MM.FRIENDS.none != @config.friends
      for citizen in @citizens
        citizen.resetFriends()

      for citizen in @citizens
        if MM.FRIENDS.random == @config.friends
          citizen.makeRandomFriends(@config.friendsNumber)
        else if MM.FRIENDS.cliques == @config.friends
          citizen.makeCliqueFriends(@config.friendsNumber)
        else if MM.FRIENDS.local == @config.friends
          citizen.makeLocalFriends(@config.friendsNumber)

  set: (key, value) ->
    if key == "view"
      @views.changed()
    else if key == "friends"
      @resetAllFriends()
    else if key == "medium"
      @media.changed()
    else
      @config[key] = value
      @config.check()

  actives: ->
    actives = []
    for citizen in @citizens
      if citizen.active and not (citizen.fighting() or citizen.imprisoned())
        actives.push citizen
    return actives

  micros: ->
    micros = []
    if MM.TYPES.micro == @config.type
      for citizen in @citizens
        if !citizen.active and citizen.activism > 0 and
            not citizen.imprisoned()
          micros.push citizen
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
        if citizen.mediumMirror() and citizen.mediumMirror().online()
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

  testAdvance: (key, hash) ->
    if @config[key] < Object.keys(hash).length - 1
      @config[key] += 1
    else
      @config[key] = 0

  testStep: ->
    if @animator.ticks % 2 == 0
      @testAdvance("calculation", MM.CALCULATIONS)
      if @config.calculation == 0
        @testAdvance("legitimacyCalculation", MM.LEGITIMACY_CALCULATIONS)

    if @animator.ticks % 7 == 0
      @testAdvance("view", MM.VIEWS)
      @views.changed()

#    if @animator.ticks % 12 == 0 TODO, errors out
#      @testAdvance("friends", MM.FRIENDS)
#      @resetAllFriends()

    if @animator.ticks % 20 == 0
      @testAdvance("medium", MM.MEDIA)
      if @config.medium == 0
        @testAdvance("mediumType", MM.MEDIUM_TYPES)
      @media.changed()

    if @animator.ticks > 20 * Object.keys(MM.MEDIA).length * Object.keys(MM.MEDIUM_TYPES).length
      console.log 'Test completed!'
      @stop()
