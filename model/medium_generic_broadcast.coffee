class MM.MediumGenericBroadcast extends MM.Medium
  setup: ->
    super

    @channels = new ABM.Array

    for n in [0..7]
      @newChannel(n)

  createAgent: (original) ->
    agent = super

    if !agent.channel
      agent.channel = @channels[u.randomInt(@channels.length)]

    return agent

  newChannel: (number) ->
    newChannel = new ABM.Array

    newChannel.number = number

    newChannel.message = (message) ->
      message.previous = @last()
      if message.previous?
        message.previous.next = message
  
      message.channel = @
  
      @push(message)

      if @length > message.from.model.world.max.y + 1
        message = @shift()

        for reader, index in message.readers by -1
          reader.toNextRead()
        
        message.destroy()

    newChannel.destroy = ->
      for message in @
        message.destroy() # takes readers as well

    @channels.unshift newChannel

    if @channels.length > @world.max.x + 1
      throw "Too many channels for world size"

  newMessage: (from) ->
    @route new MM.Message from

  route: (message) ->
    message.from.channel.message message

  drawAll: ->
    @copyOriginalColors()
    @resetPatches()

    for channel, i in @channels
      #x = i % (@world.max.x + 1)
      for message, j in channel
        patch = @patches.patch(x: i, y: j)
        @colorPatch(patch, message)

    for agent, i in @agents
      x = agent.channel.number

      agent.moveTo x: x, y: 0
