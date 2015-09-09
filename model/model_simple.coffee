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
        count = @countNeighbors(@config.vision)
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
