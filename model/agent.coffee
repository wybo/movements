class MM.Agent extends ABM.Agent
  constructor: ->
    super

    @mediumMirrors = new ABM.Array # TODO move to model
    @viewMirrors = new ABM.Array # TODO move to model

  mediumMirror: ->
    @mediumMirrors[@model.config.medium]

  viewMirror: ->
    @viewMirrors[@model.config.view]

  setColor: (color) ->
    @color = new u.color color
    @sprite = null

  countCopsActives: (vision, patch) ->
    cops = 0
    actives = 0

    if patch
      neighbors = patch.neighborAgents(vision)
    else
      neighbors = @neighbors(vision)

    for agent in neighbors
      if agent.breed.name is "cops"
        cops += 1
      else
        if @model.config.type is MM.TYPES.micro
          if agent.breed.name is "citizens"
            actives += agent.activeMicro
        else
          if agent.breed.name is "citizens" and agent.active
            actives += 1

    return {cops: cops, actives: actives}

  calculateArrestProbability: (count) ->
    if @model.config.calculation == MM.CALCULATIONS.epstein
      return 1 - Math.exp(-1 * @config.kConstant * cops / actives)
    else if @model.config.calculation == MM.CALCULATIONS.wilensky
      return 1 - Math.exp(-1 * @config.kConstant * Math.floor(cops / actives))
    else if @model.config.calculation == MM.CALCULATIONS.overpowered
      if count.cops * 5 > count.actives
        return 1 - Math.exp(-1 * @config.kConstant * count.cops / count.actives)
      else
        return 0
    else # real
      if count.cops > count.actives
        return 1
      else
        fraction = count.cops / count.actives
        if fraction < 0.20
          return 0
        else
          return fraction

  moveToRandomEmptyNeighbor: (walk) ->
    empty = @randomEmptyNeighbor(walk)

    if empty
      @moveTo(empty.position)

  # Assumes a world with an y-axis that runs from -X to X
  #
  moveToRandomUpperHalf: (walk, upper = true) ->
    empties = @randomEmptyNeighbors(walk)

    # Already up there
    if upper and @position.y > 0
      toEmpty = empties.sample((o) -> o.position.y > 0)
    else if !upper and @position.y <= 0
      toEmpty = empties.sample((o) -> o.position.y <= 0)
    else
      toEmpty = null
      if upper
        mostVertical = @model.world.min.y - 1
      else
        mostVertical = @model.world.max.y + 1

      for empty in empties
        vertical = empty.position.y

        # Edge up
        if (vertical > mostVertical and upper) or
            (vertical < mostVertical and !upper)
          mostVertical = vertical
          toEmpty = empty
    
    @moveTo(toEmpty.position) if toEmpty

  moveToRandomEmptyLocation: ->
    @moveTo(@model.patches.sample((patch) -> patch.empty()).position)

  moveToArrestProbability: (walk, vision, highest = true) ->
    empties = @randomEmptyNeighbors(walk)
    toEmpty = empties.pop()
    mostArrest = @calculateArrestProbability(@countCopsActives(vision, toEmpty)) if toEmpty
    for empty in empties
      arrest = @calculateArrestProbability(@countCopsActives(vision, empty))
      if (arrest > mostArrest and highest) or
          (arrest < mostArrest and !highest)
        mostArrest = arrest
        toEmpty = empty
    
    @moveTo(toEmpty.position) if toEmpty

  randomEmptyNeighbor: (walk) ->
    @patch.neighbors(walk).sample((patch) -> patch.empty())

  randomEmptyNeighbors: (walk) ->
    @patch.neighbors(walk).select((patch) -> patch.empty()).shuffle()
