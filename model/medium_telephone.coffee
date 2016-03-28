class MM.MediumTelephone extends MM.Medium
  setup: ->
    super

  use: (original) ->
    agent = super(original)

    agent.step = ->
      if u.randomInt(3) == 1
        @call()

      if @reading
        if @timer < 0
          @disconnect()
        @timer -= 1

    agent.call = ->
      if @links.length == 0
        me = @ # taken into closure
        agent = null # needed or may keep previous' use
        if u.randomInt(3) < 2 # 2/3rd chanche
          agent = config.sampleFriend.call(@)
        agent ?= @model.agents.sample(condition: (o) -> me.id != o.id)

        agent.disconnect()

        @model.links.create(@, agent).last()
        agent.timer = u.randomInt(3)

        agent.read(new MM.Message @, agent)

    agent.disconnect = ->
      for link in @links
        link.to.closeMessage()
        link.to.timer = null
        link.die()
      @timer = 0 # for disconnect due to offline

    agent.toNextMessage = ->
      # No need to always call

  drawAll: ->
    @copyOriginalColors()
    @resetPatches()

    for agent in @agents
      if agent.original.position # Not jailed
        agent.moveTo(agent.original.position)
        if agent.reading
          patch = @patches.patch(agent.position)
          @colorPatch(patch, agent.reading)
