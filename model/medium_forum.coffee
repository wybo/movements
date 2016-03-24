class MM.MediumForum extends MM.Medium
  setup: ->
    super

    @threads = new ABM.Array

    @newThread(@dummyAgent)
    @dummyAgent.reading = @threads[0][0]

    while @threads.length <= @world.max.x
      @newPost(@dummyAgent)

  use: (original) ->
    agent = super(original)

    agent.step = ->
      if u.randomInt(10) == 1
        @model.newPost(@)

      @toNextReading()

    agent.toNextReading = (countIt) ->
      if @reading and @reading.thread.next?
        @read(@reading.thread.next.first(), countIt)
      else
        @read(@model.threads[0][0], countIt)

      tries = 0
      while @reading.active != @original.active and tries < 10 and
          (!@config.mediaRiskAversionHomophilous or @original.riskAverse == @reading.riskAverse)
        if @reading.thread.next?
          @read(@reading.thread.next.first(), false)
        else
          @read(@model.threads[0][0], false)
        tries += 1

      while @reading.next?
        @read(@reading.next, countIt)

  newPost: (agent) -> # TODO move to agent
    if u.randomInt(10) == 1
      @newThread(agent)
    else
      @newComment(agent)

  newThread: (agent) -> # TODO same
    newThread = new ABM.Array
    if @config.mediaRiskAversionHomophilous
      newThread.riskAverse = agent.original.riskAverse
    
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

    newThread.post new MM.Message agent

    @threads.unshift newThread
    
    if @threads.length > @world.max.x + 1
      thread = @threads.pop()
      thread.destroy()

  newComment: (agent) ->
    if agent.reading
      agent.reading.thread.post new MM.Message agent

  drawAll: ->
    @copyOriginalColors()
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
