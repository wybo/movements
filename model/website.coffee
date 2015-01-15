class Website extends Medium
  setup: ->
    super

    @messages = new ABM.Array

    while @messages.length < 100
      @newPage(@dummyAgent)

  step: ->
    for agent in @agents
      if u.randomInt(20) == 1
        @newPage(agent)
      else
        agent.moveTo(@messages.sample().position)

  use: (twin) ->
    agent = @createAgent(twin)
    agent.moveTo(@messages.sample().position)

  newPage: (agent) ->
    patch = @patches.sample()
    @colorPost(patch, agent)

    @messages.unshift patch
    if @messages.length > 100
      oldPage = @messages.pop()
      oldPage.color = u.color.white
