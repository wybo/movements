class MM.MediumTV extends MM.MediumGenericBroadcast
  setup: ->
    super

  step: ->
    for agent in @agents
      if u.randomInt(3) == 1
        @newReport(agent)
      else
        agent.watchTV()

    @drawAll()

  use: (original) ->
    agent = @createAgent(original)
    agent.watchTV = ->
      agent.read(@channel[0])
