# Copyright 2014, Wybo Wiersma, available under the GPL v3
# This model builds upon Epsteins model of protest, and illustrates
# the possible impact of social media on protest formation.

class MM.View extends ABM.Model
  setup: ->
    for patch in @patches.create()
      patch.color = u.color.white

  populate: (model) ->
    for original in model.agents
      @createAgent(original)

  step: ->
    for agent in @agents
      if agent.original.position
        agent.moveTo agent.original.position
      else
        agent.moveOff()

  createAgent: (original) ->
    @agents.create 1
    agent = @agents.last()
    agent.original = original
    original.viewMirrors[original.model.config.view] = agent

    agent.size = @size
    agent.shape = "square"
