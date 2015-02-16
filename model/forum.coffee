class Forum extends Medium
  setup: ->
    super

    @threads = new ABM.Array

    @newThread(@dummyAgent)
    @dummyAgent.reading = @threads[0][0]

    while @threads.length <= @world.max.x
      @newPost(@dummyAgent)

  use: (twin) -> # TODO make super
    agent = @createAgent(twin)
    agent.read(@threads[0][0])

  step: ->
    for agent in @agents
      if agent # might have died already
        if u.randomInt(20) == 1
          @newPost(agent)

        @moveForward(agent)

    @drawAll()

  newPost: (agent) ->
    if u.randomInt(7) == 1
      @newThread(agent)
    else
      @newComment(agent)

  newThread: (agent) ->
    newThread = new ABM.Array
    
    newThread.next = @threads.first()
    if newThread.next?
      newThread.next.previous = newThread

    newThread.post = (post) ->
      post.previous = @last()
      if post.previous?
        post.previous.next = post

      post.thread = @

      @push(post)

    newThread.destroy = ->
      @previous.next = null

      for message in @
        message.destroy() # takes readers as well

    newThread.post new Message from: agent, active: agent.twin.active

    @threads.unshift newThread
    
    if @threads.length > @world.max.x + 1
      thread = @threads.pop()
      thread.destroy()

  newComment: (agent) ->
    agent.reading.thread.post new Message from: agent, active: agent.twin.active

  moveForward: (agent) ->
    reading = agent.reading

    if reading.next?
      agent.read(reading.next)
    else if reading.thread.next?
      agent.read(reading.thread.next.first())
    else
      agent.die()
    
  drawAll: ->
    @resetPatches()

    for thread, i in @threads
      for post, j in thread
        if i <= @world.max.x and j <= @world.max.y
          post.patch = @patches.patch x: i, y: @world.max.y - j
          @colorPatch(post.patch, post)
        else
          post.patch = null

    for agent in @agents
      if agent.reading.patch?
        agent.moveTo(agent.reading.patch.position)
