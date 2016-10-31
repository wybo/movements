class MM.MediumGenericDelivery extends MM.Medium
  setup: ->
    super

    @inboxes = new ABM.Array

  createAgent: (original) ->
    agent = super(original)

    if !agent.inbox
      agent.inbox = @inboxes[agent.original.id] = new ABM.Array

    agent.readInbox = ->
      while @inbox.length > 0
        @toNextReading()

    agent.toNextReading = (countIt) ->
      message = @inbox.shift()
      if message
        @read(message, countIt)

    return agent

  newMessage: (from, to) ->
    @route new MM.Message from, to

  route: (message) ->
    @inboxes[message.to.original.id].push message

  drawAll: ->
    @copyOriginalColors()
    @resetPatches()

    xOffset = yOffset = 0
    for agent, i in @agents
      x = i % (@world.max.x + 1)
      yOffset = Math.floor(i / (@world.max.x + 1)) * 5

      for message, j in agent.inbox
        patch = @patches.patch(x: x, y: yOffset + j)
        @colorPatch(patch, message)

      agent.moveTo x: x, y: yOffset
