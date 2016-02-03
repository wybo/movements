class MM.MediumWebsite extends MM.Medium
  setup: ->
    super

    @sites = new ABM.Array

    while @sites.length < 100
      @newPage(@dummyAgent)

  use: (original) ->
    agent = super(original)

    agent.step = ->
      if u.randomInt(20) == 1
        @model.newPage(@)

      @toNextMessage()

    agent.toNextMessage = ->
      @read(@model.sites.sample())

  newPage: (agent) ->
    @sites.unshift new MM.Message agent

    if @sites.length > 100
      site = @sites.pop()
      site.destroy()

  drawAll: ->
    @copyOriginalColors()
    @resetPatches()

    for site in @sites
      if !site.patch?
        site.patch = @patches.sample()

      @colorPatch(site.patch, site) # TODO reduce

    for agent in @agents
      agent.moveTo(agent.reading.patch.position)
