class MM.MediumNewspaper extends MM.MediumGenericBroadcast
  setup: ->
    super

  step: ->
    for agent in @agents by -1
      if u.randomInt(20) == 1
        @newMessage(agent)
      
      agent.toNextMessage()

    @drawAll()

  use: (original) ->
    agent = @createAgent(original)

    agent.toNextMessage = ->
      @read(@channel.sample()) # TODO not self!

  drawAll: ->
    @copyOriginalColors()
    @resetPatches()

    channelStep = Math.floor(@world.max.x / (@channels.length + 1))

    xOffset = channelStep
    for channel, i in @channels
      for message, j in channel
        for agent, k in message.readers
          agent.moveTo x: xOffset - k, y: j

        patch = @patches.patch(x: xOffset, y: j)
        @colorPatch(patch, message)

      xOffset += channelStep
