# Copyright 2014, Wybo Wiersma, available under the GPL v3
# This model builds upon Epsteins model of protest, and illustrates
# the possible impact of social media on protest formation.

Function::property = (property) ->
  for key, value of property
    Object.defineProperty @prototype, key, value

class MM.Medium extends ABM.Model
  setup: ->
    @size = 0.6

    @dummyAgent = {
      original: {active: false, activism: 0.0, config: @config}
      read: (->)
      dummy: true
    }

    for patch in @patches.create()
      patch.color = u.color.white

  createAgent: (original) ->
    if !original.mediumMirror()
      agent = @agents.create(1).last()
      agent.config = @config
      agent.original = original
      original.mediumMirrors[@config.medium] = agent

      agent.size = @size
      agent.heading = u.degreesToRadians(270)
      agent.color = original.color
      agent.count = {reads: 0, actives: 0, activism: 0}

      agent.read = (message) ->
        @closeMessage()

        if message
          message.readers.push(@)
          @count.reads += 1
          if message.active
            @count.actives += 1
          @count.activism += message.activism

        @reading = message

      agent.closeMessage = ->
        if @reading
          @reading.readers.remove(@)

        @reading = null

      agent.resetCount = ->
        @count = {reads: 0, actives: 0, activism: 0}

    return original.mediumMirror()

  colorPatch: (patch, message) ->
    if message.activism == 1.0
      patch.color = u.color.salmon
    else if message.activism > 0 and (MM.MEDIUM_TYPES.micro == @config.mediumType or MM.MEDIUM_TYPES.uncensored == @config.mediumType)
      patch.color = u.color.pink
    else
      patch.color = u.color.lightgray

  resetPatches: ->
    for patch in @patches
      patch.color = u.color.white

  copyOriginalColors: ->
    for agent in @agents
      agent.color = agent.original.color
