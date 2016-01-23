class MM.ViewGeneric extends MM.View
  setup: ->
    @size = 1.0
    super

  populate: (options) ->
    super(options)

    for citizen in @citizens
      if MM.VIEWS.hardship == @config.view
        citizen.color = u.color.red.fraction(citizen.original.hardship)
      else if MM.VIEWS.risk_aversion == @config.view
        citizen.color = u.color.red.fraction(citizen.original.riskAversion)

    for cop in @cops
      cop.color = cop.original.color

  step: ->
    super

    if MM.VIEWS.arrest_probability == @config.view
      for citizen in @citizens
        citizen.color = u.color.red.fraction(citizen.original.arrestProbability())
    else if MM.VIEWS.net_risk == @config.view
      for citizen in @citizens
        citizen.color = u.color.red.fraction(citizen.original.netRisk())
    else if MM.VIEWS.regime_legitimacy == @config.view
      for citizen in @citizens
        citizen.color = u.color.red.fraction(citizen.original.regimeLegitimacy())
    else if MM.VIEWS.grievance == @config.view
      for citizen in @citizens
        citizen.color = u.color.red.fraction(citizen.original.grievance())
