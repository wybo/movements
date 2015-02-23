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
