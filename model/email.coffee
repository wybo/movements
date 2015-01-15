class EMail extends Medium
  setup: ->
    super

    @inboxes = new ABM.Array

  step: ->
    for agent in @agents
      if u.randomInt(20) == 1
        @newMail(agent)
      else
        agent.read()

    @drawAll()

  use: (twin) ->
    agent = @createAgent(twin)
    agent.inbox = @newInbox(agent)
    agent.read = ->
      @inbox.pop()

  newInbox: (agent) ->
    @inboxes[agent.twin.id] = new ABM.Array
    @inboxes[agent.twin.id]

  newMail: (agent) ->
    @route new EmailMessage from: agent, to: @agents.sample(), active: agent.twin.active

  route: (message) ->
    @inboxes[message.to.twin.id].push message

  drawAll: ->
    x_offset = y_offset = 0
    for agent, i in @agents
      x = i %% (@world.max.x + 1)
      y_offset = Math.floor(i / (@world.max.x + 1)) * 5

      for message, j in agent.inbox
        patch = @patches.patch(x: x, y: y_offset + j)

        @colorPatch(patch, message)
        lastPatch = patch

      if lastPatch?
        white = @patches.patch x: lastPatch.position.x, y: lastPatch.position.y + 1
        white.color = u.color.white

      agent.moveTo x: x, y: y_offset
