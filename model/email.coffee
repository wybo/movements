class EMail extends Medium
  setup: ->
    super

    @inboxes = new ABM.Array

  step: ->
    for agent in @agents
      if u.randomInt(3) == 1
        @newMail(agent)
      else
        agent.readMail()

    @drawAll()

  use: (twin) ->
    agent = @createAgent(twin)
    agent.inbox = @inboxes[agent.twin.id] = new ABM.Array
    agent.readMail = ->
      agent.read(@inbox.pop())

  newMail: (agent) ->
    @route new Message from: agent, to: @agents.sample(), active: agent.twin.active

  route: (message) ->
    @inboxes[message.to.twin.id].push message

  drawAll: ->
    @resetPatches()

    x_offset = y_offset = 0
    for agent, i in @agents
      x = i %% (@world.max.x + 1)
      y_offset = Math.floor(i / (@world.max.x + 1)) * 5

      for message, j in agent.inbox
        patch = @patches.patch(x: x, y: y_offset + j)
        @colorPatch(patch, message)

      agent.moveTo x: x, y: y_offset
