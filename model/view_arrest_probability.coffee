class MM.ViewArrestProbability extends MM.View
  setup: ->
    @size = 1.0
    super

  populate: (options) ->
    super(options)

    for agent in @agents
      if agent.original.breed.name is "cops"
        agent.color = agent.original.color

  step: ->
    super

    for agent in @agents
      if agent.original.breed.name is "citizens"
        agent.color = u.color.red.fraction(agent.original.arrestProbability())
