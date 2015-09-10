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
          if MM.TYPES.enclave == @config.type
            if @riskAversion < 0.5
              @moveToRandomUpperHalf(@config.walk)
            else
              @moveToRandomBottomHalf(@config.walk)
          else if MM.TYPES.focal_point == @config.type
            if @riskAversion < 0.5
              @moveTowardsPoint(@config.walk, {x: 0, y: 0})
            else
              @moveAwayFromPoint(@config.walk, {x: 0, y: 0})
          else
            if @config.activesAdvance and @active
              @advance()
            else
              @moveToRandomEmptyNeighbor(@config.walk)

          @activate()

      citizen.grievance = ->
        @hardship * (1 - @config.regimeLegitimacy)

      citizen.arrestProbability = ->
        count = @countNeighbors(vision: @config.vision)

        if MM.MEDIA.none != @config.medium and @mediumMirror()
          count = @scaleDownNeighbors(count, @config.mediumCountsFor)
  
        if MM.TYPES.micro == @config.type
          count.actives = count.activism

        count.actives += 1
        count.citizens += 1

        if MM.MEDIA.none != @config.medium and @mediumMirror()
          mediumCount = @mediumMirror().countFor(@config.mediumCountsFor)

          if MM.MEDIUM_TYPES.micro == @config.mediumType or MM.MEDIUM_TYPES.uncensored == @config.mediumType
            count.actives += mediumCount.activism
          else
            count.actives += mediumCount.actives

          count.citizens += mediumCount.reads # mediumCountsFor

          @mediumMirror().resetCount()

        @calculatePerceivedArrestProbability(count)

      citizen.excitement = ->
        count = @countNeighbors(vision: @config.vision)
       
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

        status = @calculateActiveStatus(activation)
        @active = status.active
        @activism = status.activism

        if @active
          @setColor "red"
        else
          if @activism > 0 and MM.TYPES.micro == @config.type
            @setColor "orange"
          else
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
        count = @countNeighbors(vision: @config.vision)
        count.cops += 1

        if @config.copsRetreat and @calculateCopWillMakeArrestProbability(count) < u.randomFloat()
          @retreat()
        else
          @makeArrest()
          @moveToRandomEmptyNeighbor()

      cop.retreat = ->
        @moveTowardsArrestProbability(@config.walk, @config.vision, true)

      cop.makeArrest = ->
          protester = @neighbors(@config.vision).sample(condition: (agent) ->
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
    if MM.TYPES.micro == @config.type
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
