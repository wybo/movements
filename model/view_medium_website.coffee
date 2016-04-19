class MM.ViewMediumWebsite extends MM.ViewMedium
  step: ->
    super

    for site in @originalModel.sites
      if !site.patch?
        site.patch = @patches.sample() # Tad messy, only one view per model

      @colorPatch(site.patch, site)

    for agent in @agents
      if agent.original.online()
        agent.moveTo(agent.original.reading.patch.position)
