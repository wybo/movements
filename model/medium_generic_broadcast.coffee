class MM.MediumGenericBroadcast extends MM.Medium
  setup: ->
    super

    @channels = new ABM.Array

    for n in [0..@config.mediaChannels]
      @newChannel(n)

  createAgent: (original) ->
    agent = super(original)

    if !agent.channel
      if @config.mediaRiskAversionHomophilous # TODO finish for other media as well
        agent.channel = @channels.sample(condition: (o) -> o.riskAverse == agent.riskAverse)
      else
        agent.channel = @channels[u.randomInt(@channels.length)]

    return agent

  newChannel: (number) ->
    newChannel = new ABM.Array
    if @config.mediaRiskAversionHomophilous
      newChannel.riskAverse == false
      if number % 2 == 0
        newChannel.riskAverse == true

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

  newMessage: (from) ->
    @route new MM.Message from

  route: (message) ->
    message.from.channel.message message
