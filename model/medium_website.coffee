class MM.MediumWebsite extends MM.Medium
  setup: ->
    super

    @sites = new ABM.Array

    while @sites.length < 100
      @newPage(@dummyAgent)

  createAgent: (original) ->
    agent = super(original)

    agent.step = ->
      if u.randomInt(20) == 1
        @model.newPage(@)

      for [1..5]
        @toNextReading()

    agent.toNextReading = (countIt) ->
      @read(@model.sites.sample(), countIt)

  newPage: (agent) ->
    @sites.unshift new MM.Message agent

    if @sites.length > 100
      site = @sites.pop()
      site.destroy()
