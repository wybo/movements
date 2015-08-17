class MM.ViewFollow extends MM.View
  setup: ->
    @size = 1.0
    super

  populate: (model) ->
    super(model)

    @agent = model.citizens.first().viewMirror()

  step: ->
    super

    for agent in @agents
      agent.color = u.color.white

    for agent in @agent.neighbors(@agent.original.config.vision)
      agent.color = agent.original.color

    @agent.color = u.color.black
