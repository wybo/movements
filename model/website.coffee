class MM.Website extends MM.Medium
  setup: ->
    super

    @sites = new ABM.Array

    while @sites.length < 100
      @newPage(@dummyAgent)

  use: (twin) ->
    @createAgent(twin)

  step: ->
    for agent in @agents
      if u.randomInt(20) == 1
        @newPage(agent)

      @moveToRandomPage(agent)

    @drawAll()

  newPage: (agent) ->
    @sites.unshift new MM.Message from: agent, active: agent.twin.active
    @dropSite()

  dropSite: ->
    if @sites.length > 100
      site = @sites.pop()
      for reader, index in site.readers by -1
        @moveToRandomPage(reader)

  moveToRandomPage: (agent) ->
    agent.read(@sites.sample())

  drawAll: ->
    @copyTwinColors()
    @resetPatches()

    for site in @sites
      if !site.patch?
        site.patch = @patches.sample()

      @colorPatch(site.patch, site) # TODO reduce

    for agent in @agents
      agent.moveTo(agent.reading.patch.position)
