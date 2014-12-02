# Copyright 2014, Wybo Wiersma, available under the GPL v3
# This model builds upon Epsteins model of protest, and illustrates
# the possible impact of social media on protest formation.

class Medium extends ABM.Model
  setup: ->
    @size = 0.6

    # Shape to bitmap for better performance.
    @agents.setUseSprites()

    @animator.setRate 20, false

    @messages = new ABM.Array

    @dummyAgent = {position: {x: 0, y: @world.max.y}, color: u.color.lightgray, twin: {active: false}, dummy: true}

    for patch in @patches.create()
      patch.color = u.color.white

  createAgent: (twin) ->
    @agents.create 1
    agent = @agents.last()
    agent.size = @size
    agent.heading = u.degreesToRadians(270)
    agent.twin = twin
    agent.color = twin.color

    return agent

  colorPost: (patch, agent) ->
    if agent.twin.active
      patch.color = u.color.orange
    else
      patch.color = u.color.lightgray
