# Copyright 2014, Wybo Wiersma, available under the GPL v3
# This model builds upon Epsteins model of protest, and illustrates
# the possible impact of social media on protest formation.

Function::property = (property) ->
  for key, value of property
    Object.defineProperty @prototype, key, value

class MM.Medium extends ABM.Model
  setup: ->
    @size = 0.6

    @mirrors = []

    @dummyAgent = {
      original: {active: false, activism: 0.0, grievance: (->), calculateActiveStatus: (-> @), config: @config}
      config: @config
      read: (->)
      dummy: true
    }

    for patch in @patches.create()
      patch.color = u.color.white

  populate: ->
    for original in @originalModel.agents
      if original.breed.name == "citizens"
        @createAgent(original)

  access: (original) ->
    agent = @mirrors[original.id]

    if !agent # Agents replacing defected cops are new
      agent = @createAgent(original)

    agent.onlineTimer = @config.mediaOnlineTime # activates medium

    return agent

  step: ->
    for agent in @agents by -1
      if agent.online()
        agent.resetCount()
        agent.step()

      agent.onlineTimer -= 1

    @drawAll()

  createAgent: (original) ->
    agent = @agents.create(1).last()
    agent.config = @config
    agent.original = original
    @mirrors[original.id] = agent

    agent.size = @size
    agent.heading = u.degreesToRadians(270)
    agent.color = original.color
    # agent.count below

    agent.online = ->
      @onlineTimer > 0

    agent.read = (message, countIt = true) ->
      if @config.mediaMaxReadNr and @count.reads > @config.mediaMaxReadNr
        countIt = false

      @closeMessage()

      if message and countIt
        message.readers.push(@)
        @count.reads += 1
        if message.active
          @count.actives += 1
        @count.activism += message.activism
        if message.evidence
          @count.evidences += 1

      @reading = message

    agent.closeMessage = ->
      if @reading
        @reading.readers.remove(@)

      @reading = null

    agent.resetCount = ->
      @count = {reads: 0, actives: 0, activism: 0, evidences: 0}

    agent.resetCount()

    return agent

  colorPatch: (patch, message) ->
    if message.arrest
      patch.color = u.color.mediumpurple
    else if message.activism == 1.0
      patch.color = u.color.salmon
    else if message.activism > 0
      patch.color = u.color.pink
    else
      patch.color = u.color.lightgray

  resetPatches: ->
    for patch in @patches
      patch.color = u.color.white

  copyOriginalColors: ->
    for agent in @agents
      agent.color = agent.original.color

  drawAll: ->
