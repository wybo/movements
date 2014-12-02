class Forum extends Medium
  setup: ->
    super

    @newThread(@dummyAgent)

    while @messages.length < @world.max.x
      @newPost(@dummyAgent)

  step: ->
    for agent in @agents by -1
      if u.randomInt(20) == 1
        @newPost(agent)
      else
        agent.forward 1, snap: true
        if agent.patch.color == u.color.white or agent.position.y == 0
          agent.moveTo(x: agent.position.x + 1, y: @world.max.y)
      if agent.position.x > @world.max.x
        agent.die()

  use: (twin) ->
    agent = @createAgent(twin)
    agent.moveTo(x: 0, y: @world.max.y)

  newPost: (agent) ->
    if u.randomInt(7) == 1
      @newThread(agent)
    else
      @newComment(agent)

  newThread: (agent) ->
    opener = null

    for patch in @patches by -1
      if patch.position.x > 0
        previous = @patches.patch x: patch.position.x - 1, y: patch.position.y
        patch.color = previous.color
        for agent in previous.agents by -1
          agent.moveTo patch.position
      else
        if patch.position.y == @world.max.y
          opener = patch
        else
          patch.color = u.color.white

    @colorPost(opener, agent)

    @messages.unshift new ABM.Array opener
    if @messages.length > @world.max.x
      @messages.pop

  newComment: (agent) ->
    patch = @patches.patch(x: agent.position.x, y: @messages[agent.position.x].last().position.y - 1)
    @colorPost(patch, agent)
    @messages[agent.position.x].push patch
