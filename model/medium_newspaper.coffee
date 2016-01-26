class MM.MediumNewspaper extends MM.MediumGenericBroadcast
  setup: ->
    super

  step: ->
    for agent in @agents
      if u.randomInt(3) == 1
        @newMessage(agent)
      else
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

    avg_add = 0
    avg_div = 0
    x_offset = channelStep
    for channel, i in @channels
      for message, j in channel
        if j == 1
          avg_add += message.readers.length
          avg_div += 1

        for agent, k in message.readers
          agent.moveTo x: x_offset - k, y: j

        patch = @patches.patch(x: x_offset, y: j)
        @colorPatch(patch, message)

      x_offset += channelStep
    
    console.log avg_add / avg_div
