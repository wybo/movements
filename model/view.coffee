# Copyright 2014, Wybo Wiersma, available under the GPL v3
# This model builds upon Epsteins model of protest, and illustrates
# the possible impact of social media on protest formation.

class MM.View extends ABM.Model
  setup: ->
    # Improves performance
    @agents.setUseSprites() # Bitmap for better performance.
    @animator.setRate 20, false

    @agentBreeds ["citizens", "cops"]
    @patches.create()

  populate: ->
    for original in @originalModel.agents
      @createAgent(original)

  step: ->
    for patch in @patches
      patch.color = u.color.white

  createAgent: (original) ->
    if original.breed.name == "citizens"
      @citizens.create 1
    else
      @cops.create 1

    agent = @agents.last()
    agent.original = original

    agent.size = @size
    agent.shape = @shape
    agent.heading = u.degreesToRadians(270)
