class MM.MediumGenericDelivery extends MM.Medium
  setup: ->
    super

    @inboxes = new ABM.Array

  createAgent: (original) ->
    agent = super

    if !agent.inbox
      agent.inbox = @inboxes[agent.original.id] = new ABM.Array

    return agent

  newMessage: (from, to) ->
    @route new MM.Message from, to

  route: (message) ->
    @inboxes[message.to.original.id].push message

  drawAll: ->
    @copyOriginalColors()
    @resetPatches()

    x_offset = y_offset = 0
    for agent, i in @agents
      x = i % (@world.max.x + 1)
      y_offset = Math.floor(i / (@world.max.x + 1)) * 5

      for message, j in agent.inbox
        patch = @patches.patch(x: x, y: y_offset + j)
        @colorPatch(patch, message)

      agent.moveTo x: x, y: y_offset
