# Copyright 2014, Wybo Wiersma, available under the GPL v3
# This model builds upon Epsteins model of protest, and illustrates
# the possible impact of social media on protest formation.

Function::property = (property) ->
  for key, value of property
    Object.defineProperty @prototype, key, value

class Medium extends ABM.Model
  setup: ->
    @size = 0.6

    # Shape to bitmap for better performance.
    @agents.setUseSprites()

    @animator.setRate 20, false

    @dummyAgent = {twin: {active: false}, read: (->), dummy: true}

    for patch in @patches.create()
      patch.color = u.color.white

  createAgent: (twin) ->
    @agents.create 1
    agent = @agents.last()
    agent.twin = twin
    twin.twins[twin.model.config.medium] = agent

    agent.size = @size
    agent.heading = u.degreesToRadians(270)
    agent.color = twin.color

    agent.read = (message) ->
      @closeMessage()

      if message
        message.readers.push(@)

      @reading = message

    agent.closeMessage = ->
      if @reading?
        @reading.readers.remove(@)

      @reading = null

    return agent

  colorPatch: (patch, message) ->
    if message.active
      patch.color = u.color.pink
    else
      patch.color = u.color.lightgray

  resetPatches: ->
    for patch in @patches
      patch.color = u.color.white
