class MM.Agent extends ABM.Agent
  constructor: ->
    super

    @mediumMirrors = new ABM.Array # TODO move to model
    @viewMirrors = new ABM.Array # TODO move to model

    @friends_hash = {}
    @friends = []

  mediumMirror: ->
    @mediumMirrors[@config.medium]

  viewMirror: ->
    @viewMirrors[@config.view]

  setColor: (color) ->
    @color = new u.color color
    @sprite = null

  #### Calculations and counting

  calculateActiveStatus: (activation, threshold, thresholdMicro) ->
    if activation > @config.threshold
      return {activism: 1.0, active: true}
    else if activation > @config.thresholdMicro
      return {activism: 0.4, active: false}
    else
      return {activism: 0.0, active: false}

  calculatePerceivedArrestProbability: (count) ->
    return @calculateCopWillMakeArrestProbability(count) *
      @calculateSpecificCitizenArrestProbability(count)

  calculateSpecificCitizenArrestProbability: (count) ->
    if MM.CALCULATIONS.epstein == @config.calculation or MM.CALCULATIONS.overpowered == @config.calculation
      return 1 - Math.exp(-1 * @config.kConstant * count.cops / count.actives)
    else if MM.CALCULATIONS.wilensky == @config.calculation
      return 1 - Math.exp(-1 * @config.kConstant * Math.floor(count.cops / count.actives))
    else # real
      if count.cops > count.actives
        return 1
      else
        return count.cops / count.actives

  calculateCopWillMakeArrestProbability: (count) ->
    if MM.CALCULATIONS.overpowered == @config.calculation
      if count.cops * 5 > count.actives
        return 1
      else
        return 0
    else if MM.CALCULATIONS.real == @config.calculation
      overwhelm = count.cops * 7 / count.actives
      if overwhelm > 1
        return 1
      else
        return overwhelm
    else
      return 1

  calculateExcitement: (count) ->
    return (count.actives / count.citizens) ** 2

  countNeighbors: (options) ->
    cops = 0
    actives = 0
    citizens = 0
    activism = 0

    if options.patch
      neighbors = options.patch.neighborAgents(options.vision)
    else
      neighbors = @neighbors(options.vision)

    for agent in neighbors
      if agent.breed.name is "cops"
        cops += 1
      else
        if @config.friends and @config.friendsMultiplier != 1 and @isFriendsWith(agent)
          friendsMultiplier = @config.friendsMultiplier
        else
          friendsMultiplier = 1

        citizens += friendsMultiplier

        if agent.active
          actives += friendsMultiplier

        activism += agent.activism * friendsMultiplier

    return {cops: cops, citizens: citizens, actives: actives, activism: activism}

  scaleDownNeighbors: (count, fraction) ->
    if fraction and fraction < 1
      count.actives = count.actives * fraction
      count.citizens = count.citizens * fraction
      count.activism = count.activism * fraction
    return count

  removeNeighbors: (count, remove) ->
    if remove and remove > 0
      newCitizens = count.citizens - remove
      if newCitizens > 0
        factor = newCitizens / count.citizens
        count.actives = count.actives * factor
        count.citizens = newCitizens
        count.activism = count.activism * factor
      else
        count.citizens = count.actives = count.activism = 0
  
    return count

  #### Movement

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
      toEmpty = empties.sample(condition: (o) -> o.position.y > 0)
    else if !upper and @position.y <= 0
      toEmpty = empties.sample(condition: (o) -> o.position.y <= 0)
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

  moveTowardsArrestProbability: (walk, vision, highest = true) ->
    empties = @randomEmptyNeighbors(walk)
    toEmpty = empties.pop()
    mostArrest = @calculatePerceivedArrestProbability(@countNeighbors(vision: vision, patch: toEmpty)) if toEmpty
    for empty in empties
      arrest = @calculatePerceivedArrestProbability(@countNeighbors(vision: vision, patch: empty))
      if (arrest > mostArrest and highest) or
          (arrest < mostArrest and !highest)
        mostArrest = arrest
        toEmpty = empty
    
    @moveTo(toEmpty.position) if toEmpty

  moveAwayFromArrestProbability: (walk, vision) ->
    @moveTowardsArrestProbability(walk, vision, false)

  moveToRandomEmptyLocation: ->
    @moveTo(@model.patches.sample(condition: (patch) -> patch.empty()).position)

  moveToRandomEmptyNeighbor: (walk) ->
    empty = @randomEmptyNeighbor(walk)

    if empty
      @moveTo(empty.position)

  randomEmptyNeighbor: (walk) ->
    @patch.neighbors(walk).sample(condition: (patch) -> patch.empty())

  randomEmptyNeighbors: (walk) ->
    @patch.neighbors(walk).select((patch) -> patch.empty()).shuffle()

  #### Misc

  isFriendsWith: (citizen) ->
    @friends_hash[citizen.id]

  makeRandomFriends: (number) ->
    needed = number - @friends.length # friends already made by others
    id = @id # taken into closure
    if @config.friendsHardshipHomophilous
      hardship = @hardship
      friends = @model.citizens.sample(size: needed, condition: (o) ->
        o.friends.length < number and id != o.id and (hardship >= 0.5 and o.hardship >= 0.5 or hardship < 0.5 and o.hardship < 0.5)
      )
    else
      friends = @model.citizens.sample(size: needed, condition: (o) ->
        o.friends.length < number and id != o.id
      )

    if friends # TODO FIX!
      for friend in friends
        @friends.push friend
        friend.friends.push @
        @friends_hash[friend.id] = true
        friend.friends_hash[@id] = true
