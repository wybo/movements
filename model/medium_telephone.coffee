class MM.MediumTelephone extends MM.Medium
  setup: ->
    super

  createAgent: (original) ->
    agent = super(original)

    agent.step = ->
      if !@reading
        if u.randomInt(3) == 1
          @call()

      if @initiated_call
        if @timer < 0
          @disconnect()
        @timer -= 1

    agent.call = ->
      me = @ # taken into closure
      agent = null # needed or may keep previous' use
      if u.randomInt(3) < 2 # 2/3rd chanche
        agent = @config.sampleOnlineFriend.call(@)
      agent ?= @model.agents.sample(condition: (o) -> me.id != o.id and o.online())

      agent.disconnect()

      @timer = 5
      @initiated_call = true

      @read(new MM.Message agent, @)
      agent.read(new MM.Message @, agent)

    agent.disconnect = ->
      if @reading
        for reader in @reading.readers
          reader.closeMessage()
          reader.timer = 0
          reader.initiated_call = false

        @closeMessage()
        @timer = 0 # for disconnect due to offline
        @initiated_call = false

    agent.toNextMessage = ->
      # No need to always call

      #  drawAll: ->
      #    @copyOriginalColors()
      #    @resetPatches()
      #
      #    for agent in @agents
      #      if agent.original.position # Not jailed
      #        agent.moveTo(agent.original.position)
      #        if agent.reading
      #          patch = @patches.patch(agent.position)
      #          @colorPatch(patch, agent.reading)
