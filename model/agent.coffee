class MM.Agent extends ABM.Agent
  constructor: ->
    super

    @resetFriends()

  setColor: (color) ->
    @color = new u.color color
    @sprite = null

  #### Calculations and counting

  calculatePerceivedArrestProbability: (count) ->
    return @config.copWillMakeArrestProbability.call(@, count) *
      @config.citizenArrestProbability.call(@, count)

  countNeighbors: (options) ->
    cops = 0
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
        if @config.friends and @isFriendsWith(agent)
          friendsMultiplier = @config.friendsMultiplier
          if @config.friendsRevealFearless
            agentActivism = agent.fearless_activism
          else
            agentActivism = agent.activism
        else
          friendsMultiplier = 1
          agentActivism = agent.activism

        if @config.notifyOfProtest
          if @notified or agent.active or !agent.notified # if self not notified, other has to be neither
            activism += agentActivism * friendsMultiplier
        else
          activism += agentActivism * friendsMultiplier

        citizens += friendsMultiplier

        if agent.fighting()
          arrests += friendsMultiplier

    return {cops: cops, citizens: citizens, activism: activism, arrests: arrests}

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

  swapToActiveSquare: (point, options) ->
    if @patch.distance(point, dimension: true) > options.range
      center = @model.patches.patch point
      options.meToo = true
      inactive = center.neighborAgents(options).sample(condition: (o) -> o.breed.name is "citizens" and !o.active)
      if inactive
        former_patch = @patch
        to_patch = inactive.patch
        inactive.moveOff()
        @moveTo(to_patch.position)
        inactive.moveTo(former_patch.position)

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

  #### Media

  mediaMirrors: ->
    if !@mirrorsCache
      @mirrorsCache = new ABM.Array
      for medium in @model.media.adopted
        if medium.mirrors[@id]
          @mirrorsCache.push medium.mirrors[@id]

    return @mirrorsCache

  online: ->
    for mirror in @mediaMirrors()
      if mirror.online()
        return true

  goOffline: ->
    for mirror in @mediaMirrors()
      mirror.onlineTimer = 0
  
  mediaTickReset: ->
    for mirror in @mediaMirrors()
      mirror.resetCount()
    @mirrorsCache = null

  #### Friends & befriending

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

  selectFiends: (list, number) ->
    needed = number - @friends.length # friends already made by others
    id = @id # taken into closure
    friendsHash = @friendsHash
    if @config.friendsHardshipHomophilous
      hardshipped = @hardshipped
      friends = list.sample(size: needed, condition: (o) ->
        o.friends.length < number and !friendsHash[o.id] and id != o.id and hardshipped == o.hardshipped
      )
    else if @config.friendsRiskAversionHomophilous
      riskAverse = @riskAverse
      friends = list.sample(size: needed, condition: (o) ->
        o.friends.length < number and !friendsHash[o.id] and id != o.id and riskAverse == o.riskAverse
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
    for agent in list
      @beFriend(agent)

  makeClique: (list) ->
    list.push(@) # self included in clique
    for agent in list
      agent.beFriendList(list)

  #### Notices

  leaveNotice: ->
    @patch.noticeCounter = 10
    @patch.color = u.color.gray
