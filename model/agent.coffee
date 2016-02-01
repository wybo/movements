class MM.Agent extends ABM.Agent
  constructor: ->
    super

    @mediumMirrors = new ABM.Array # TODO move to model
    @viewMirrors = new ABM.Array # TODO move to model

    @resetFriends()

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

  calculateLegitimacyDrop: (count) ->
    return count.arrests / (count.citizens - count.actives)
    # could consider taking min of cops + actives, police-violence
    # or arrests
    # Make active agents share photos of fights
    # Two things expressed. Grievance/active and photos 

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

  countNeighbors: (options) ->
    cops = 0
    actives = 0
    citizens = 0
    arrests = 0
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

        if agent.fighting()
          arrests += friendsMultiplier
        if agent.active
          actives += friendsMultiplier

        activism += agent.activism * friendsMultiplier

    return {cops: cops, citizens: citizens, actives: actives, activism: activism, arrests: arrests}

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

  resetFriends: ->
    @friendsHash = {}
    @friends = new ABM.Array

  isFriendsWith: (citizen) ->
    @friendsHash[citizen.id]

  makeRandomFriends: (number) ->
    list = @selectFiends(@model.citizens, number)
    @beFriendList(list)

  makeCliqueFriends: (number) ->
    list = @selectFiends(@model.citizens, number)
    @makeClique(list)

  makeLocalFriends: (number) ->
    neighbors = @neighbors(range: @config.friendsLocalRange)
    oldFriends = @friends
    oldFriendsHash = @friendsHash
    @resetFriends()
    potentialFriends = new ABM.Array
    for neighbor in neighbors
      if oldFriendsHash[neighbor.id]
        @friendsHash[neighbor.id] = true
        @friends.push(neighbor)
      else
        potentialFriends.push(neighbor)

    if @friends.length < number
      list = @selectFiends(potentialFriends, number)
      @beFriendList(list)

    for oldFriend in oldFriends
      if !@friendsHash[oldFriend.id]
        oldFriend.oneSidedUnFriend(@)

    console.log @friends.length

  selectFiends: (list, number) ->
    needed = number - @friends.length # friends already made by others
    id = @id # taken into closure
    friendsHash = @friendsHash
    if @config.friendsHardshipHomophilous
      hardship = @hardship
      friends = list.sample(size: needed, condition: (o) ->
        o.friends.length < number and !friendsHash[o.id] and id != o.id and (hardship >= 0.5 and o.hardship >= 0.5 or hardship < 0.5 and o.hardship < 0.5)
      )
    else
      friends = list.sample(size: needed, condition: (o) ->
        o.friends.length < number and !friendsHash[o.id] and id != o.id
      )
    return friends

  beFriend: (agent) ->
    if agent != @ and !@friendsHash[agent.id]
      @friends.push agent
      agent.friends.push @
      @friendsHash[agent.id] = true
      agent.friendsHash[@id] = true

  oneSidedUnFriend: (agent) ->
    if agent != @ and @friendsHash[agent.id]
      @friends.remove(agent)
      @friendsHash[agent.id] = null

  beFriendList: (list) ->
    if list # TODO FIX!
      for agent in list
        @beFriend(agent)

  makeClique: (list) ->
    if list # TODO FIX!
      list.push(@) # self included in clique
      for agent in list
        agent.beFriendList(list)
