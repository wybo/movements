class MM.ViewMediumNewspaper extends MM.ViewMedium
  step: ->
    super

    channelStep = Math.floor(@world.max.x / (@model.channels.length + 1))

    xOffset = channelStep
    for channel, i in @model.channels
      for message, j in channel
        for agent, k in message.readers
          agent.mirror.moveTo x: xOffset - k, y: j

        patch = @patches.patch(x: xOffset, y: j)
        @colorPatch(patch, message)

      xOffset += channelStep
