class MM.ViewMediumTV extends MM.ViewMedium
  step: ->
    super

    channelStep = Math.floor(@world.max.x / (@model.channels.length + 1))

    xOffset = channelStep
    for channel, i in @model.channels
      message = channel[0]
      if message
        for agent, j in message.readers
          k = j - 1

          if j == 0
            agent.mirror.moveTo x: xOffset, y: 0
          else
            column_nr = Math.floor(k / (@world.max.y + 1))
            agent.mirror.moveTo x: xOffset - column_nr - 1, y: k % (@world.max.y + 1)

      for message, j in channel
        patch = @patches.patch(x: xOffset, y: j)
        @colorPatch(patch, message)

      xOffset += channelStep
