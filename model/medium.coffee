# Copyright 2014, Wybo Wiersma, available under the GPL v3
# This model builds upon Epsteins model of protest, and illustrates
# the possible impact of social media on protest formation.

Function::property = (property) ->
  for key, value of property
    Object.defineProperty @prototype, key, value

class MM.Medium extends ABM.Model
  setup: ->
    @size = 0.6

    @dummyAgent = {original: {active: false}, read: (->), dummy: true}

    for patch in @patches.create()
      patch.color = u.color.white

  createAgent: (original) ->
    if !original.mediumMirror()
      @agents.create 1
      agent = @agents.last()
      agent.original = original
      original.mediumMirrors[original.model.config.medium] = agent

      agent.size = @size
      agent.heading = u.degreesToRadians(270)
      agent.color = original.color
      agent.count = {posts: 0, activism: 0}

      agent.read = (message) ->
        @closeMessage()

        if message
          message.readers.push(@)
          @count.posts += 1
          @count.activism += message.activism

        @reading = message

      agent.closeMessage = ->
        if @reading?
          @reading.readers.remove(@)

        @reading = null

      agent.resetCount = ->
        @count = {posts: 0, activism: 0}

    return original.mediumMirror()

  colorPatch: (patch, message) ->
    if message.activism == 1.0
      patch.color = u.color.pink
    else if message.activism > 0
      patch.color = u.color.orange
    else
      patch.color = u.color.lightgray

  resetPatches: ->
    for patch in @patches
      patch.color = u.color.white

  copyOriginalColors: ->
    for agent in @agents
      agent.color = agent.original.color
