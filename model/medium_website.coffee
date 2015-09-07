class MM.MediumWebsite extends MM.Medium
  setup: ->
    super

    @sites = new ABM.Array

    while @sites.length < 100
      @newPage(@dummyAgent)

  use: (original) ->
    @createAgent(original)

  step: ->
    for agent in @agents
      if u.randomInt(20) == 1
        @newPage(agent)

      @moveToRandomPage(agent)

    @drawAll()

  newPage: (agent) ->
    @sites.unshift new MM.Message agent
    @dropSite()

  dropSite: ->
    if @sites.length > 100
      site = @sites.pop()
      for reader, index in site.readers by -1
        @moveToRandomPage(reader)

  moveToRandomPage: (agent) ->
    agent.read(@sites.sample())

  drawAll: ->
    @copyOriginalColors()
    @resetPatches()

    for site in @sites
      if !site.patch?
        site.patch = @patches.sample()

      @colorPatch(site.patch, site) # TODO reduce

    for agent in @agents
      agent.moveTo(agent.reading.patch.position)
