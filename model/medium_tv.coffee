class MM.MediumTV extends MM.MediumGenericBroadcast
  setup: ->
    super

  step: ->
    for agent in @agents
      if u.randomInt(3) == 1
        @newMessage(agent)
      
      agent.toNextMessage()

    @drawAll()

  use: (original) ->
    agent = @createAgent(original)

    agent.toNextMessage = ->
      @read(@channel[0])

  drawAll: ->
    @copyOriginalColors()
    @resetPatches()

    channelStep = Math.floor(@world.max.x / (@channels.length + 1))

    x_offset = channelStep
    for channel, i in @channels
      message = channel[0]
      if message
        for agent, j in message.readers
          k = j - 1

          if j == 0
            agent.moveTo x: x_offset, y: 0
          else
            column_nr = Math.floor(k / (@world.max.y + 1))
            agent.moveTo x: x_offset - column_nr - 1, y: k % (@world.max.y + 1)

      for message, j in channel
        patch = @patches.patch(x: x_offset, y: j)
        @colorPatch(patch, message)

      x_offset += channelStep
