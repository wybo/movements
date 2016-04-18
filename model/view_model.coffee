class MM.ViewModel extends MM.View
  setup: ->
    @size = 1.0
    @shape = "square"
    super

  step: ->
    super

    for agent in @agents
      if agent.original.position
        agent.moveTo agent.original.position
      else
        agent.moveOff()
