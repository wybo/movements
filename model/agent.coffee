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

  calculatePerceivedArrestProbability: (count) ->
    return @calculateCopWillMakeArrestProbability(count) *
      @calculateSpecificCitizenArrestProbability(count)

  calculateSpecificCitizenArrestProbability: (count) ->
    if MM.CALCULATIONS.epstein == @model.config.calculation or MM.CALCULATIONS.overpowered == @model.config.calculation
      return 1 - Math.exp(-1 * @config.kConstant * count.cops / count.actives)
    else if MM.CALCULATIONS.wilensky == @model.config.calculation
      return 1 - Math.exp(-1 * @config.kConstant * Math.floor(count.cops / count.actives))
    else # real
      if count.cops > count.actives
        return 1
      else
        return count.cops / count.actives

  calculateCopWillMakeArrestProbability: (count) ->
    if MM.CALCULATIONS.overpowered == @model.config.calculation
      if count.cops * 5 > count.actives
        return 1
      else
        return 0
    else if MM.CALCULATIONS.real == @model.config.calculation
      return count.cops * 7 / count.actives
    else
      return 1

  moveToRandomEmptyNeighbor: (walk) ->
    empty = @randomEmptyNeighbor(walk)

    if empty
      @moveTo(empty.position)

  moveTowardsPoint: (walk, point, towards = true) ->
    empties = @randomEmptyNeighbors(walk)
    toEmpty = empties.pop()
    lowestDistance = toEmpty.distance(point) if toEmpty
    for empty in empties
      distance = empty.distance(point)
      if (distance < lowestDistance and towards) or
          (distance > lowestDistance and !towards)
        lowestDistance = distance
        toEmpty = empty
    
    @moveTo(toEmpty.position) if toEmpty

  moveAwayFromPoint: (walk, point) ->
    @moveTowardsPoint(walk, point, false)

  # Assumes a world with an y-axis that runs from -X to X
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
        mostVertical = @model.world.minCoordinate.y
      else
        mostVertical = @model.world.maxCoordinate.y

      for empty in empties
        vertical = empty.position.y

        # Edge up
        if (vertical > mostVertical and upper) or
            (vertical < mostVertical and !upper)
          mostVertical = vertical
          toEmpty = empty
    
    @moveTo(toEmpty.position) if toEmpty

  moveToRandomBottomHalf: (walk) ->
    @moveToRandomUpperHalf(walk, false)

  moveToRandomEmptyLocation: ->
    @moveTo(@model.patches.sample((patch) -> patch.empty()).position)

  moveTowardsArrestProbability: (walk, vision, highest = true) ->
    empties = @randomEmptyNeighbors(walk)
    toEmpty = empties.pop()
    mostArrest = @calculatePerceivedArrestProbability(@countCopsActives(vision, toEmpty)) if toEmpty
    for empty in empties
      arrest = @calculatePerceivedArrestProbability(@countCopsActives(vision, empty))
      if (arrest > mostArrest and highest) or
          (arrest < mostArrest and !highest)
        mostArrest = arrest
        toEmpty = empty
    
    @moveTo(toEmpty.position) if toEmpty

  moveAwayFromArrestProbability: (walk, vision) ->
    @moveTowardsArrestProbability(walk, vision, false)

  randomEmptyNeighbor: (walk) ->
    @patch.neighbors(walk).sample((patch) -> patch.empty())

  randomEmptyNeighbors: (walk) ->
    @patch.neighbors(walk).select((patch) -> patch.empty()).shuffle()
