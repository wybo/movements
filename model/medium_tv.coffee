class MM.MediumTV extends MM.MediumGenericBroadcast
  setup: ->
    super

  use: (original) ->
    agent = super(original)

    agent.step = ->
      if u.randomInt(50) == 1
        @model.newMessage(@)
      
      @toNextReading()

    agent.toNextReading = (countIt) ->
      @read(@channel[0], countIt)

  drawAll: ->
    @copyOriginalColors()
    @resetPatches()

    channelStep = Math.floor(@world.max.x / (@channels.length + 1))

    xOffset = channelStep
    for channel, i in @channels
      message = channel[0]
      if message
        for agent, j in message.readers
          k = j - 1

          if j == 0
            agent.moveTo x: xOffset, y: 0
          else
            column_nr = Math.floor(k / (@world.max.y + 1))
            agent.moveTo x: xOffset - column_nr - 1, y: k % (@world.max.y + 1)

      for message, j in channel
        patch = @patches.patch(x: xOffset, y: j)
        @colorPatch(patch, message)

      xOffset += channelStep
