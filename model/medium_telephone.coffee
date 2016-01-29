class MM.MediumTelephone extends MM.Medium
  setup: ->
    super

  use: (original) ->
    agent = @createAgent(original)

    agent.call = ->
      if @links.length == 0
        id = @id # taken into closure
        agent = @model.agents.sample(condition: (a) ->
          id != a.id)
        agent.hangUp()

        @model.links.create(@, agent).last()
        agent.timer = u.randomInt(3)

        agent.read(new MM.Message @, agent)

    agent.hangUp = ->
      for link in @links
        link.to.closeMessage()
        link.to.timer = null
        link.die()

    agent.toNextMessage = ->
      # No need to always call

  step: ->
    for agent in @agents by -1
      if u.randomInt(3) == 1
        agent.call()

      if agent.reading
        if agent.timer < 0
          agent.hangUp()
        agent.timer -= 1
      
    @drawAll()

  drawAll: ->
    @copyOriginalColors()
    @resetPatches()

    for agent in @agents
      if agent.original.position # Not jailed
        agent.moveTo(agent.original.position)
        if agent.reading
          patch = @patches.patch(agent.position)
          @colorPatch(patch, agent.reading)
