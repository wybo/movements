class EMail extends Medium
  setup: ->
    super

  step: ->
    for agent in @agents
      if u.randomInt(20) == 1
        @newMail(agent)
      else
        @readMessage(agent)

    @setPatches()

  setPatches: ->
    x_offset = y_offset = 0
    for agent, i in @agents
      x = i %% (@world.max.x + 1)
      y_offset = Math.floor(i / (@world.max.x + 1)) * 5

      for message, j in agent.inbox
        patch = @patches.patch(x: x, y: y_offset + j)

        @colorPost(patch, twin: message)
        lastPatch = patch

      if lastPatch?
        white = @patches.patch x: lastPatch.position.x, y: lastPatch.position.y + 1
        white.color = u.color.white

      agent.moveTo x: x, y: y_offset

  use: (twin) ->
    agent = @createAgent(twin)
    agent.inbox = Message.inbox(agent)

  newMail: (agent) ->
    new Message from: agent, to: @agents.sample(), active: agent.twin.active

  readMessage: (agent) ->
    message = Message.read(agent)
