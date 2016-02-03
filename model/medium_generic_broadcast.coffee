class MM.MediumGenericBroadcast extends MM.Medium
  setup: ->
    super

    @channels = new ABM.Array

    for n in [0..7]
      @newChannel(n)

  use: (original) ->
    agent = super(original)

    if !agent.channel
      agent.channel = @channels[u.randomInt(@channels.length)]

    return agent

  newChannel: (number) ->
    newChannel = new ABM.Array

    newChannel.number = number

    newChannel.message = (message) ->
      message.channel = @
  
      @unshift(message)

      if @length > message.from.model.world.max.y + 1
        @pop().destroy()

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
