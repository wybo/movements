class MM.MediumEMail extends MM.MediumGenericDelivery
  setup: ->
    super

  step: ->
    for agent in @agents by -1
      if u.randomInt(3) == 1
        @newMessage(agent, @agents.sample())
        
      agent.toNextMessage()

    @drawAll()

  use: (original) ->
    agent = @createAgent(original)
