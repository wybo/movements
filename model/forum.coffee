class Forum extends Medium
  setup: ->
    super

    @threads = new ABM.Array

    @dummyAgent.reading = {threadNr: 0, postNr: 0}

    @newThread(@dummyAgent)

    while @threads.length < @world.max.x
      @newPost(@dummyAgent)

  step: ->
    for agent in @agents
      if agent # might have died already
        if u.randomInt(20) == 1
          @newPost(agent)
        else
          @moveForward(agent)

    @drawAll()

  use: (twin) ->
    agent = @createAgent(twin)
    agent.reading = {threadNr: 0, postNr: 0}

  newPost: (agent) ->
    if u.randomInt(7) == 1
      @newThread(agent)
    else
      @newComment(agent)

  newThread: (agent) ->
    @threads.unshift new ABM.Array new Message from: agent, active: agent.active

    for agent in @agents
      if agent # might have died already
        agent.reading.threadNr += 1
        @fallOffWorld(agent)

    if @threads.length > @world.max.x
      @threads.pop

  newComment: (agent) ->
    if @threads[agent.reading.threadNr].length <= @world.max.y
      @threads[agent.reading.threadNr].push new Message from: agent, active: agent.twin.active

  moveForward: (agent) ->
    console.log agent
    agent.reading.postNr += 1
    if agent.reading.postNr >= @threads[agent.reading.threadNr].length
      agent.reading.threadNr += 1
      agent.reading.postNr = 0
      @fallOffWorld(agent)

  fallOffWorld: (agent) ->
    if agent.reading.threadNr > @world.max.x
      agent.die()

  drawAll: ->
    for patch in @patches
      patch.color = u.color.white

    for thread, i in @threads
      for post, j in thread
        patch = @patches.patch x: i, y: @world.max.y - j
        @colorPatch(patch, post)

    for agent in @agents
      agent.moveTo(x: agent.reading.threadNr, y: @world.max.y - agent.reading.postNr)
