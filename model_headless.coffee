# Copyright 2014, Wybo Wiersma, available under the GPL v3. Please
# cite with url, and author Wybo Wiersma (and if applicable, a paper).
# This model builds upon Epsteins model of protest, and illustrates
# the possible impact of social media on protest formation.

@MM = MM = {}

if typeof ABM == 'undefined'
  code = require "./lib/agentbase.coffee"
  eval 'var ABM = this.ABM = code.ABM'

u = ABM.util # ABM.util alias
log = (object) -> console.log object

indexHash = (array) ->
  hash = {}
  i = 0
  for key in array
    hash[key] = "#{i++}"

  return hash

MM.TYPES = indexHash(["normal", "enclave", "focalPoint", "micro"])
MM.CALCULATIONS = indexHash(["epstein", "wilensky", "overpowered", "real"])
MM.LEGITIMACY_CALCULATIONS = indexHash(["base", "arrests"])
MM.FRIENDS = indexHash(["none", "random", "cliques", "local"])
MM.MEDIA = indexHash(["none", "tv", "newspaper", "telephone", "email", "website", "forum", "facebookWall"])
MM.MEDIUM_TYPES = indexHash(["normal", "uncensored"]) # TODO micro, from original agent
MM.VIEWS = indexHash(["none", "riskAversion", "hardship", "grievance", "regimeLegitimacy", "arrestProbability", "netRisk", "follow"])
# turn back to numbers once dat.gui fixed

class MM.Config
  constructor: ->
    @type = MM.TYPES.normal
    @calculation = MM.CALCULATIONS.real
    @legitimacyCalculation = MM.LEGITIMACY_CALCULATIONS.arrests
    @friends = MM.FRIENDS.local
    @medium = MM.MEDIA.forum
    @mediumType = MM.MEDIUM_TYPES.uncensored
    @view = MM.VIEWS.arrestProbability
    
    @copsRetreat = false
    @activesAdvance = false
    @friendsNumber = 30 # also used for Fb
    @friendsMultiplier = 2 # 1 actively cancels out friends
    @friendsHardshipHomophilous = true # If true range has to be 6 min, and friends max 30 or will have fewer
    @friendsLocalRange = 6

    @citizenDensity = 0.7
    #@copDensity = 0.04
    #@copDensity = 0.012
    @copDensity = 0.03
    @arrestDuration = 2
    @maxPrisonSentence = 30 # J
    #@baseRegimeLegitimacy = 0.85 # L
    @baseRegimeLegitimacy = 0.82 # L
    #@baseRegimeLegitimacy = 0.82 # best with base
    @threshold = 0.1
    @thresholdMicro = 0.0
    #@vision = {diamond: 7} # Neumann 7, v and v*
    @vision = {radius: 7} # Neumann 7, v and v*
    @walk = {radius: 2} # Neumann 7, v and v*
    @kConstant = 2.3 # k

    @ui = {
      passives: {label: "Passives", color: "green"},
      actives: {label: "Actives", color: "red"},
      micros: {label: "Micros", color: "orange"},
      arrests: {label: "Arrests", color: "purple"},
      prisoners: {label: "Prisoners", color: "black"},
      cops: {label: "Cops", color: "blue"},
      media: {label: "Media", color: "black"}
    }

    # ### Do not modify below unless you know what you're doing.

    sharedModelOptions = {
      patchSize: 20
      #mapSize: 15
      mapSize: 20
      #mapSize: 30
      isTorus: true
    }

    @modelOptions = u.merge(sharedModelOptions, {
      Agent: MM.Agent
      div: "world"
      # config is added
    })

    @viewModelOptions = u.merge(sharedModelOptions, {
      div: "view"
    })

    @mediaModelOptions = {
      div: "medium"
      #patchSize: 15
      patchSize: 10
      min: {x: 0, y: 0}
      max: {x: 39, y: 39}
    }

    @mediaMirrorModelOptions = u.merge(sharedModelOptions, {
      div: "medium"
      # config is added
    })

    @config = @

  makeHeadless: ->
    @modelOptions.isHeadless = true
    @viewModelOptions.isHeadless = true
    @mediaModelOptions.isHeadless = true
    @mediaMirrorModelOptions.isHeadless = true

class MM.Message
  constructor: (from, to) ->
    @from = from
    @to = to
    @readers = new ABM.Array

    if MM.MEDIUM_TYPES.uncensored == @from.original.config.mediumType
      status = @from.original.calculateActiveStatus(@from.original.grievance(), true)
      @active = status.active
      @activism = status.activism
    else
      @active = @from.original.active
      @activism = @from.original.activism

    @arrest = @from.original.sawArrest
  
  destroy: ->
    for reader in @readers by -1
      reader.toNextMessage()

# Copyright 2014, Wybo Wiersma, available under the GPL v3
# This model builds upon Epsteins model of protest, and illustrates
# the possible impact of social media on protest formation.

Function::property = (property) ->
  for key, value of property
    Object.defineProperty @prototype, key, value

class MM.Medium extends ABM.Model
  setup: ->
    @size = 0.6

    @dummyAgent = {
      original: {active: false, activism: 0.0, grievance: (->), calculateActiveStatus: (-> @), config: @config}
      read: (->)
      dummy: true
    }

    for patch in @patches.create()
      patch.color = u.color.white

  step: ->
    for agent in @agents by -1
      if agent.online()
        agent.step()

      agent.onlineTimer -= 1

    @drawAll()

  use: (original) ->
    agent = original.mediumMirror()

    if !agent
      agent = @agents.create(1).last()
      agent.config = @config
      agent.original = original
      original.mediumMirrors[@config.medium] = agent

      agent.size = @size
      agent.heading = u.degreesToRadians(270)
      agent.color = original.color
      # agent.count below

      agent.online = ->
        @onlineTimer > 0

      agent.read = (message) ->
        @closeMessage()

        if message
          message.readers.push(@)
          @count.reads += 1
          if message.active
            @count.actives += 1
          @count.activism += message.activism
          if message.arrest
            @count.arrests += 1

        @reading = message

      agent.closeMessage = ->
        if @reading
          @reading.readers.remove(@)

        @reading = null

      agent.resetCount = ->
        @count = {reads: 0, actives: 0, activism: 0, arrests: 0}

      agent.resetCount()

    agent.onlineTimer = 5 # activates medium

    return agent

  colorPatch: (patch, message) ->
    if message.arrest
      patch.color = u.color.mediumpurple
    else if message.activism == 1.0
      patch.color = u.color.salmon
    else if message.activism > 0
      patch.color = u.color.pink
    else
      patch.color = u.color.lightgray

  resetPatches: ->
    for patch in @patches
      patch.color = u.color.white

  copyOriginalColors: ->
    for agent in @agents
      agent.color = agent.original.color

class MM.MediumGenericDelivery extends MM.Medium
  setup: ->
    super

    @inboxes = new ABM.Array

  use: (original) ->
    agent = super(original)

    if !agent.inbox # TODO really needed?
      agent.inbox = @inboxes[agent.original.id] = new ABM.Array

    agent.toNextMessage = ->
      @read(@inbox.pop())

    return agent

  newMessage: (from, to) ->
    @route new MM.Message from, to

  route: (message) ->
    @inboxes[message.to.original.id].push message

  drawAll: ->
    @copyOriginalColors()
    @resetPatches()

    xOffset = yOffset = 0
    for agent, i in @agents
      x = i % (@world.max.x + 1)
      yOffset = Math.floor(i / (@world.max.x + 1)) * 5

      for message, j in agent.inbox
        patch = @patches.patch(x: x, y: yOffset + j)
        @colorPatch(patch, message)

      agent.moveTo x: x, y: yOffset

class MM.Agent extends ABM.Agent
  constructor: ->
    super

    @mediumMirrors = new ABM.Array
    @mediumMirrors[MM.MEDIA.none] = false
    @viewMirrors = new ABM.Array
    @viewMirrors[MM.VIEWS.none] = false

    @resetFriends()

  mediumMirror: ->
    @mediumMirrors[@config.medium]

  viewMirror: ->
    @viewMirrors[@config.view]

  setColor: (color) ->
    @color = new u.color color
    @sprite = null

  #### Calculations and counting

  calculateActiveStatus: (activation, withMicro) ->
    if activation > @config.threshold
      return {activism: 1.0, active: true}
    else if withMicro and activation > @config.thresholdMicro
      return {activism: 0.4, active: false}
    else
      return {activism: 0.0, active: false}

  calculateLegitimacyDrop: (count) ->
    return count.arrests / (count.citizens - count.activism)
    # could consider taking min of cops + activism, police-violence
    # or arrests
    # Make active agents share photos of fights
    # Two things expressed. Grievance/active and photos 

  calculatePerceivedArrestProbability: (count) ->
    return @calculateCopWillMakeArrestProbability(count) *
      @calculateSpecificCitizenArrestProbability(count)

  calculateSpecificCitizenArrestProbability: (count) ->
    if MM.CALCULATIONS.epstein == @config.calculation or MM.CALCULATIONS.overpowered == @config.calculation
      return 1 - Math.exp(-1 * @config.kConstant * count.cops / count.activism)
    else if MM.CALCULATIONS.wilensky == @config.calculation
      return 1 - Math.exp(-1 * @config.kConstant * Math.floor(count.cops / count.activism))
    else # real
      if count.cops > count.activism
        return 1
      else
        return count.cops / count.activism

  calculateCopWillMakeArrestProbability: (count) ->
    if MM.CALCULATIONS.overpowered == @config.calculation
      if count.cops * 5 > count.activism
        return 1
      else
        return 0
    else if MM.CALCULATIONS.real == @config.calculation
      overwhelm = count.cops * 7 / count.activism
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

class MM.Media
  constructor: (model, options = {}) ->
    @model = model

    @media = new ABM.Array

    options = u.merge(@model.config.mediaModelOptions, {config: @model.config})
    mirrorOptions = u.merge(@model.config.mediaMirrorModelOptions, {config: @model.config})

    @media[MM.MEDIA.none] = new MM.MediumNone(options)
    @media[MM.MEDIA.tv] = new MM.MediumTV(options)
    @media[MM.MEDIA.newspaper] = new MM.MediumNewspaper(options)
    @media[MM.MEDIA.telephone] = new MM.MediumTelephone(mirrorOptions)
    @media[MM.MEDIA.email] = new MM.MediumEMail(options)
    @media[MM.MEDIA.website] = new MM.MediumWebsite(options)
    @media[MM.MEDIA.forum] = new MM.MediumForum(options)
    @media[MM.MEDIA.facebookWall] = new MM.MediumFacebookWall(options)

    @updateOld()

  current: ->
    @media[@model.config.medium]

  old: ->
    @media[@model.config.oldMedium]

  updateOld: ->
    @model.config.oldMedium = @model.config.medium

class MM.MediumEMail extends MM.MediumGenericDelivery
  setup: ->
    super

  use: (original) ->
    agent = super(original)

    agent.step = ->
      if u.randomInt(3) == 1
        @newMessage(@, @model.agents.sample())
        
      @toNextMessage()

class MM.MediumFacebookWall extends MM.MediumGenericDelivery
  setup: ->
    super

  use: (original) ->
    agent = super(original)

    agent.step = ->
      if u.randomInt(10) == 1
        @model.newPost(@) # TODO move newPost to agent

      @readPosts()

    agent.readPosts = ->
      while true
        break unless agent.toNextMessage()

      @inbox.clear()

  newPost: (agent) ->
    friends = @agents.sample(size: 30, condition: (o) ->
      agent.original.isFriendsWith(o.original)
    )

    for friend in friends
      @newMessage(agent, friend)

class MM.MediumForum extends MM.Medium
  setup: ->
    super

    @threads = new ABM.Array

    @newThread(@dummyAgent)
    @dummyAgent.reading = @threads[0][0]

    while @threads.length <= @world.max.x
      @newPost(@dummyAgent)

  use: (original) ->
    agent = super(original)

    agent.step = ->
      if u.randomInt(20) == 1
        @model.newPost(@)

      @toNextMessage()

    agent.toNextMessage = (agent) ->
      if @reading && @reading.next?
        @read(@reading.next)
      else if @reading && @reading.thread.next?
          @read(@reading.thread.next.first())
      else
        @read(@model.threads[0][0])

  newPost: (agent) ->
    if u.randomInt(7) == 1
      @newThread(agent)
    else
      @newComment(agent)

  newThread: (agent) ->
    newThread = new ABM.Array
    
    newThread.next = @threads.first()
    if newThread.next?
      newThread.next.previous = newThread

    newThread.post = (post) ->
      post.previous = @last()
      if post.previous?
        post.previous.next = post

      post.thread = @

      @push(post)

    newThread.destroy = ->
      @previous.next = null

      for message in @
        message.destroy() # takes readers as well

    newThread.post new MM.Message agent

    @threads.unshift newThread
    
    if @threads.length > @world.max.x + 1
      thread = @threads.pop()
      thread.destroy()

  newComment: (agent) ->
    if agent.reading
      agent.reading.thread.post new MM.Message agent

  drawAll: ->
    @copyOriginalColors()
    @resetPatches()

    for thread, i in @threads
      for post, j in thread
        if i <= @world.max.x and j <= @world.max.y
          post.patch = @patches.patch x: i, y: @world.max.y - j
          @colorPatch(post.patch, post)
        else
          post.patch = null

    for agent in @agents
      if agent.reading.patch?
        agent.moveTo(agent.reading.patch.position)

class MM.MediumGenericBroadcast extends MM.Medium
  setup: ->
    super

    @channels = new ABM.Array

    for n in [0..7]
      @newChannel(n)

  use: (original) ->
    agent = super(original)

    if !agent.channel
      agent.channel = @channels[u.randomInt(@channels.length)]

    return agent

  newChannel: (number) ->
    newChannel = new ABM.Array

    newChannel.number = number

    newChannel.message = (message) ->
      message.channel = @
  
      @unshift(message)

      if @length > message.from.model.world.max.y + 1
        @pop().destroy()

    newChannel.destroy = ->
      for message in @
        message.destroy() # takes readers as well

    @channels.unshift newChannel

    if @channels.length > @world.max.x + 1
      throw "Too many channels for world size"

  newMessage: (from) ->
    @route new MM.Message from

  route: (message) ->
    message.from.channel.message message

  drawAll: ->
    @copyOriginalColors()
    @resetPatches()

    for channel, i in @channels
      #x = i % (@world.max.x + 1)
      for message, j in channel
        patch = @patches.patch(x: i, y: j)
        @colorPatch(patch, message)

    for agent, i in @agents
      x = agent.channel.number

      agent.moveTo x: x, y: 0

class MM.MediumNewspaper extends MM.MediumGenericBroadcast
  setup: ->
    super

  use: (original) ->
    agent = super(original)

    agent.step = ->
      if u.randomInt(20) == 1
        @model.newMessage(@)
      
      @toNextMessage()

    agent.toNextMessage = ->
      @read(@channel.sample()) # TODO not self!

  drawAll: ->
    @copyOriginalColors()
    @resetPatches()

    channelStep = Math.floor(@world.max.x / (@channels.length + 1))

    xOffset = channelStep
    for channel, i in @channels
      for message, j in channel
        for agent, k in message.readers
          agent.moveTo x: xOffset - k, y: j

        patch = @patches.patch(x: xOffset, y: j)
        @colorPatch(patch, message)

      xOffset += channelStep

class MM.MediumNone extends MM.Medium
  setup: ->
    super

  use: (original) ->

  step: ->

class MM.MediumTelephone extends MM.Medium
  setup: ->
    super

  use: (original) ->
    agent = super(original)

    agent.step = ->
      if u.randomInt(3) == 1
        @call()

      if @reading
        if @timer < 0
          @disconnect()
        @timer -= 1

    agent.call = ->
      if @links.length == 0
        id = @id # taken into closure
        agent = @model.agents.sample(condition: (a) ->
          id != a.id)
        agent.disconnect()

        @model.links.create(@, agent).last()
        agent.timer = u.randomInt(3)

        agent.read(new MM.Message @, agent)

    agent.disconnect = ->
      for link in @links
        link.to.closeMessage()
        link.to.timer = null
        link.die()
      @timer = 0 # for disconnect due to offline

    agent.toNextMessage = ->
      # No need to always call

  drawAll: ->
    @copyOriginalColors()
    @resetPatches()

    for agent in @agents
      if agent.original.position # Not jailed
        agent.moveTo(agent.original.position)
        if agent.reading
          patch = @patches.patch(agent.position)
          @colorPatch(patch, agent.reading)

class MM.MediumTV extends MM.MediumGenericBroadcast
  setup: ->
    super

  use: (original) ->
    agent = super(original)

    agent.step = ->
      if u.randomInt(20) == 1
        @model.newMessage(@)
      
      @toNextMessage()

    agent.toNextMessage = ->
      @read(@channel[0])

  drawAll: ->
    @copyOriginalColors()
    @resetPatches()

    channelStep = Math.floor(@world.max.x / (@channels.length + 1))

    xOffset = channelStep
    for channel, i in @channels
      message = channel[0]
      if message
        for agent, j in message.readers
          k = j - 1

          if j == 0
            agent.moveTo x: xOffset, y: 0
          else
            column_nr = Math.floor(k / (@world.max.y + 1))
            agent.moveTo x: xOffset - column_nr - 1, y: k % (@world.max.y + 1)

      for message, j in channel
        patch = @patches.patch(x: xOffset, y: j)
        @colorPatch(patch, message)

      xOffset += channelStep

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

class MM.UI
  constructor: (model, options = {}) ->
    if window.modelUI
      window.modelUI.gui.domElement.remove()

    element = $("#graph")

    if element.lenght > 0
      element.remove()
    
    $("#before_graph").after(
      '<div class="model_container" style="float: left;"><div id="graph" style="width: 500px; height: 400px;"></div></div>')

    @model = model
    @plotDiv = $("#graph")
    @gui = new dat.GUI()
    @setupControls()

  setupControls: () ->
    settings =
      type: [MM.TYPES]
      calculation: [MM.CALCULATIONS]
      legitimacyCalculation: [MM.LEGITIMACY_CALCULATIONS]
      friends: [MM.FRIENDS]
      medium: [MM.MEDIA]
      mediumType: [MM.MEDIUM_TYPES]
      view: [MM.VIEWS]
      #medium: [MM.MEDIA], {onChange: 55}
      citizenDensity: {min: 0, max: 1}
      copDensity: {min: 0, max: 0.10}
      maxPrisonSentence: {min: 0, max: 1000}
      baseRegimeLegitimacy: {min: 0, max: 1}
      threshold: {min: -1, max: 1}
      thresholdMicro: {min: -1, max: 1}
      copsRetreat: null
      activesAdvance: null
      friendsNumber: null
      friendsMultiplier: {min: 0, max: 5}
      friendsHardshipHomophilous: null
      friendsLocalRange: 5

    buttons =
      step: ->
        window.model.once()
      pauseResume: ->
        window.model.toggle()
      restart: ->
        window.model.restart()

    for key, value of settings
      if key == "view"
        adder = @gui.add(@model.config, key, value...)
        adder.onChange((newView) =>
          @model.views.old().reset()
          @model.views.current().reset()
          @model.views.current().populate(@model)
          @model.views.current().start()
          @model.views.updateOld()
        )
      else if key == "friends"
        adder = @gui.add(@model.config, key, value...)
        adder.onChange((newFriends) =>
          @model.resetAllFriends()
        )
      else if key == "medium"
        adder = @gui.add(@model.config, key, value...)
        adder.onChange((newMedium) =>
          @model.media.old().reset()
          @model.media.current().restart()
          @model.media.updateOld()
          @addMediaMarker()
        )
      else if u.isArray(value)
          @gui.add(@model.config, key, value...)
      else
        adder = @gui.add(@model.config, key)
        for setting, argument of value
          adder[setting](argument)

    for key, bull of buttons
      @gui.add(buttons, key)


  resetPlot: ->
    options = {
      series: {
        shadowSize: 0
      } # faster without shadows
      yaxis: {
        min: 0
      }
      grid: {
        markings: [
          { color: "#000", lineWidth: 1, xaxis: { from: 2, to: 2 } }
        ]
      }
    }

    @model.resetData()
    @plotRioters = []
    for key, variable of @model.config.ui
      @plotRioters.push({
        label: variable.label, color: variable.color, data: @model.data[key]
      })

    @plotter = $.plot(@plotDiv, @plotRioters, options)
    @plotOptions = @plotter.getOptions()
    @drawPlot()

  drawPlot: ->
    @plotter.setData(@plotRioters)
    @plotter.setupGrid()
    @plotter.draw()

  addMediaMarker: ->
    ticks = @model.animator.ticks
    @plotOptions.grid.markings.push { color: "#000", lineWidth: 1, xaxis: { from: ticks, to: ticks } }

# Copyright 2014, Wybo Wiersma, available under the GPL v3
# This model builds upon Epsteins model of protest, and illustrates
# the possible impact of social media on protest formation.

class MM.View extends ABM.Model
  setup: ->
    @agentBreeds ["citizens", "cops"]

    for patch in @patches.create()
      patch.color = u.color.white

  populate: (model) ->
    for original in model.agents
      @createAgent(original)

  step: ->
    for agent in @agents
      if agent.original.position
        agent.moveTo agent.original.position
      else
        agent.moveOff()

  createAgent: (original) ->
    if original.breed.name == "citizens"
      @citizens.create 1
    else
      @cops.create 1

    agent = @agents.last()
    agent.original = original
    original.viewMirrors[original.model.config.view] = agent

    agent.size = @size
    agent.shape = "square"

class MM.ViewArrestProbability extends MM.View
  setup: ->
    @size = 1.0
    super

  populate: (options) ->
    super(options)

    for agent in @agents
      if agent.original.breed.name is "cops"
        agent.color = agent.original.color

  step: ->
    super

    for agent in @agents
      if agent.original.breed.name is "citizens"
        agent.color = u.color.red.fraction(agent.original.arrestProbability())

class MM.ViewFollow extends MM.View
  setup: ->
    @size = 1.0
    super

  populate: (model) ->
    super(model)

    @agent = model.citizens.first().viewMirror()

    console.log "Selected agent for following:"
    console.log @agent

  step: ->
    super

    for agent in @agents
      agent.color = u.color.white

    for agent in @agent.neighbors(@agent.original.config.vision)
      agent.color = agent.original.color

    @agent.original.color = @agent.color = u.color.black

class MM.ViewGeneric extends MM.View
  setup: ->
    @size = 1.0
    super

  populate: (options) ->
    super(options)

    for citizen in @citizens
      if MM.VIEWS.hardship == @config.view
        citizen.color = u.color.red.fraction(citizen.original.hardship)
      else if MM.VIEWS.riskAversion == @config.view
        citizen.color = u.color.red.fraction(citizen.original.riskAversion)

    for cop in @cops
      cop.color = cop.original.color

  step: ->
    super

    if MM.VIEWS.arrestProbability == @config.view
      for citizen in @citizens
        citizen.color = u.color.red.fraction(citizen.original.arrestProbability())
    else if MM.VIEWS.netRisk == @config.view
      for citizen in @citizens
        citizen.color = u.color.red.fraction(citizen.original.netRisk())
    else if MM.VIEWS.regimeLegitimacy == @config.view
      for citizen in @citizens
        citizen.color = u.color.red.fraction(citizen.original.regimeLegitimacy())
    else if MM.VIEWS.grievance == @config.view
      for citizen in @citizens
        citizen.color = u.color.red.fraction(citizen.original.grievance())

class MM.ViewNone extends MM.View
  setup: ->
    super

  populate: (options) ->

  step: ->

class MM.Views
  constructor: (model, options = {}) ->
    @model = model

    @views = new ABM.Array

    genericView = new MM.ViewGeneric(u.merge(@model.config.viewModelOptions, {config: @model.config}))

    for key, viewNumber of MM.VIEWS
      @views[viewNumber] = genericView

    @views[MM.VIEWS.none] = new MM.ViewNone(@model.config.viewModelOptions)
    @views[MM.VIEWS.follow] = new MM.ViewFollow(@model.config.viewModelOptions)

    @updateOld()

  current: ->
    @views[@model.config.view]

  old: ->
    @views[@model.config.oldView]

  updateOld: ->
    @model.config.oldView = @model.config.view

class MM.Model extends ABM.Model
  restart: ->
    @media.current().restart()

    unless @isHeadless
      @views.current().restart()

    super

  setup: ->
    @agentBreeds ["citizens", "cops"]
    @size = 0.9
    @resetData()

    for patch in @patches.create()
      if MM.TYPES.enclave == @config.type

        if patch.position.y > 0
          patch.color = u.color.random type: "gray", min: 180, max: 204
        else
          patch.color = u.color.random type: "gray", min: 234, max: 255
      else
        patch.color = u.color.random type: "gray", min: 224, max: 255

    space = @patches.length

    for citizen in @citizens.create @config.citizenDensity * space
      citizen.config = @config
      citizen.size = @size
      citizen.shape = "person"
      citizen.setColor "green"
      citizen.moveToRandomEmptyLocation()

      citizen.hardship = u.randomFloat() # H
      citizen.riskAversion = u.randomFloat() # R
      citizen.lastLegitimacyDrop = 0
      citizen.active = false
      citizen.activism = 0.0
      citizen.arrestDuration = 0
      citizen.prisonSentence = 0
      citizen.sawArrest = false

      citizen.act = ->
        if @imprisoned()
          @prisonSentence -= 1

          if !@imprisoned() # just released
            @moveToRandomEmptyLocation()

        if !@fighting() and !@imprisoned() # including just released
          if MM.TYPES.enclave == @config.type
            if @riskAversion < 0.5
              @moveToRandomUpperHalf(@config.walk)
            else
              @moveToRandomBottomHalf(@config.walk)
          else if MM.TYPES.focalPoint == @config.type
            if @riskAversion < 0.5
              @moveTowardsPoint(@config.walk, {x: 0, y: 0})
            else
              @moveAwayFromPoint(@config.walk, {x: 0, y: 0})
          else
            if @config.activesAdvance and @active
              @advance()
            else
              @moveToRandomEmptyNeighbor(@config.walk)

          if MM.FRIENDS.local == @config.friends
            @makeLocalFriends(@config.friendsNumber)

          @activate()

      citizen.grievance = ->
        @hardship * (1 - @regimeLegitimacy())

      citizen.regimeLegitimacy = ->
        if MM.LEGITIMACY_CALCULATIONS.base == @config.legitimacyCalculation
          return @config.baseRegimeLegitimacy
        else
          if @imprisoned()
            return @config.baseRegimeLegitimacy
          else
            if @mediumMirror() and @mediumMirror().online()
              count = @mediumMirror().count

              count.citizens = count.reads # TODO fix/simplify

              @mediumMirror().resetCount()
            else
              count = @countNeighbors(vision: @config.vision)

            @lastLegitimacyDrop = (@lastLegitimacyDrop + @calculateLegitimacyDrop(count)) / 2

            return @config.baseRegimeLegitimacy - @lastLegitimacyDrop

      citizen.arrestProbability = ->
        count = @countNeighbors(vision: @config.vision)

        count.activism += 1
        count.actives += 1
        count.citizens += 1

        # TODO cleanup
        if count.arrests > 0
          @sawArrest = true
        else
          @sawArrest = false

        @calculatePerceivedArrestProbability(count)

      citizen.netRisk = ->
        @arrestProbability() * @riskAversion

      citizen.imprison = ->
        @prisonSentence = 1 + u.randomInt(@config.maxPrisonSentence)
        @moveOff()

      citizen.arrest = ->
        @arrestDuration = @config.arrestDuration
        @setColor "purple"

      citizen.beatUp = ->
        @arrestDuration -= 1

      citizen.fighting = ->
        @arrestDuration > 0

      citizen.imprisoned = ->
        @prisonSentence > 0

      citizen.advance = ->
        @moveAwayFromArrestProbability(@config.walk, @config.vision)

      citizen.activate = ->
        activation = @grievance() - @netRisk()

        status = @calculateActiveStatus(activation, (MM.TYPES.micro == @config.type))
        @active = status.active
        @activism = status.activism

        if @active
          @setColor "red"
        else
          if @activism > 0
            @setColor "orange"
          else
            @setColor "green"

    @resetAllFriends()

    for cop in @cops.create @config.copDensity * space
      cop.config = @config
      cop.size = @size
      cop.shape = "person"
      cop.arresting = null
      cop.setColor "blue"
      cop.moveToRandomEmptyLocation()

      cop.act = ->
        if @fighting()
          @arresting.beatUp()
          if !@arresting.fighting()
            @arresting.imprison()
            @arresting = null
        if !@fighting()
          count = @countNeighbors(vision: @config.vision)
          count.cops += 1

          if @config.copsRetreat and @calculateCopWillMakeArrestProbability(count) < u.randomFloat()
            @retreat()
          else
            @initiateArrest()
            @moveToRandomEmptyNeighbor()

      cop.retreat = ->
        @moveTowardsArrestProbability(@config.walk, @config.vision, true)

      cop.initiateArrest = ->
          protester = @neighbors(@config.vision).sample(condition: (agent) ->
            agent.breed.name is "citizens" and
              agent.active and !agent.fighting())

          if protester
            @arresting = protester
            @arresting.arrest()

      cop.fighting = ->
        return (@arresting != null)

    unless @isHeadless
      window.modelUI.resetPlot()
      @views.current().populate(@)
      @consoleLog()

  step: -> # called by MM.Model.animate
    @agents.shuffle()
    for agent in @agents
      agent.act()
      if agent.breed.name is "citizens" and u.randomInt(20) == 1
          @media.current().use(agent)

    unless @isHeadless
      window.modelUI.drawPlot()

    @media.current().once()

    unless @isHeadless
      @views.current().once()

    @recordData()

  resetAllFriends: ->
    if MM.FRIENDS.none != @config.friends
      for citizen in @citizens
        citizen.resetFriends()

      for citizen in @citizens
        if MM.FRIENDS.random == @config.friends
          citizen.makeRandomFriends(@config.friendsNumber)
        else if MM.FRIENDS.cliques == @config.friends
          citizen.makeCliqueFriends(@config.friendsNumber)
        else if MM.FRIENDS.local == @config.friends
          citizen.makeLocalFriends(@config.friendsNumber)

  actives: ->
    actives = []
    for citizen in @citizens
      if citizen.active and not (citizen.fighting() or citizen.imprisoned())
        actives.push citizen
    return actives

  micros: ->
    micros = []
    if MM.TYPES.micro == @config.type
      for citizen in @citizens
        if !citizen.active and citizen.activism > 0 and
            not citizen.imprisoned()
          micros.push citizen
    return micros

  arrests: ->
    arrests = []
    for citizen in @citizens
      if citizen.fighting()
        arrests.push citizen
    return arrests

  prisoners: ->
    prisoners = []
    for citizen in @citizens
      if citizen.imprisoned()
        prisoners.push citizen
    return prisoners

  tickData: ->
    citizens = @citizens.length
    actives = @actives().length
    micros = @micros().length
    arrests = @arrests().length
    prisoners = @prisoners().length

    return {
      citizens: citizens
      passives: citizens - actives - micros - arrests - prisoners
      actives: actives
      micros: micros
      arrests: arrests
      prisoners: prisoners
      cops: @cops.length
    }

  resetData: ->
    @data = {
      passives: [],
      actives: [],
      micros: [],
      arrests: [],
      prisoners: [],
      cops: [],
      media: []
    }
    
  recordData: ->
    ticks = @animator.ticks
    tickData = @tickData()

    @data.passives.push [ticks, tickData.passives]
    @data.actives.push [ticks, tickData.actives]
    @data.micros.push [ticks, tickData.micros]
    @data.arrests.push [ticks, tickData.arrests]
    @data.prisoners.push [ticks, tickData.prisoners]
    @data.cops.push [ticks, tickData.cops]

  recordMediaChange: ->
    @data.media.push [ticks, 0], [ticks, @citizens.length], null

  consoleLog: ->
    console.log 'Config:'
    console.log @config
    console.log 'Calibration:'
    console.log '  Arrest Probability:'

    for count in [
        {cops: 0, activism: 1},
        {cops: 1, activism: 1}, {cops: 2, activism: 1}, {cops: 3, activism: 1},
        {cops: 1, activism: 4}, {cops: 2, activism: 4}, {cops: 3, activism: 4}
      ]
      console.log @citizens[0].calculatePerceivedArrestProbability(count)

    console.log 'Citizens:'
    console.log @citizens
    console.log 'Cops:'
    console.log @cops

class MM.ModelSimple extends ABM.Model
  # TODO actives

  restart: ->
    @media.current().restart()

    unless @isHeadless
      @views.current().restart()

    super

  setup: ->
    @agentBreeds ["citizens", "cops"]
    @size = 0.9
    @resetData()

    for patch in @patches.create()
      patch.color = u.color.random type: "gray", min: 224, max: 255

    space = @patches.length

    for citizen in @citizens.create @config.citizenDensity * space
      citizen.config = @config
      citizen.size = @size
      citizen.shape = "person"
      citizen.setColor "green"
      citizen.moveToRandomEmptyLocation()

      citizen.hardship = u.randomFloat() # H
      citizen.active = false
      citizen.prisonSentence = 0

      citizen.act = ->
        if @imprisoned()
          @prisonSentence -= 1

          if !@imprisoned() # just released
             @moveToRandomEmptyLocation()

        if !@imprisoned()
          @moveToRandomEmptyNeighbor(@config.walk)
          @activate()

      citizen.excitement = ->
        count = @countNeighbors(@config.vision)
        count.actives += 1

        return (count.actives / count.citizens) ** 2

      citizen.activate = ->
        if @excitement() > @hardship
          @active = true
          @setColor "red"
        else
          @active = false
          @setColor "green"

       citizen.imprison = (sentence) ->
         @prisonSentence = sentence
         @moveOff()

       citizen.imprisoned = ->
         @prisonSentence > 0

     for cop in @cops.create @config.copDensity * space
       cop.config = @config
       cop.size = @size
       cop.shape = "person"
       cop.setColor "blue"
       cop.moveToRandomEmptyLocation()

       cop.act = ->
         @makeArrest()
         @moveToRandomEmptyNeighbor()

       cop.makeArrest = ->
          protester = @neighbors(@config.vision).sample(condition: (agent) ->
            agent.breed.name is "citizens" and agent.active)

          if protester
            protester.imprison(1 + u.randomInt(@config.maxPrisonSentence))

    unless @isHeadless
      window.modelUI.resetPlot()
      @views.current().populate(@)
      @consoleLog()

  step: -> # called by MM.Model.animate
    @agents.shuffle()
    for agent in @agents
      agent.act()
      if u.randomInt(100) == 1
        if agent.breed.name is "citizens"
          @media.current().use(agent)

    unless @isHeadless
      window.modelUI.drawPlot()

    @media.current().once()

    unless @isHeadless
      @views.current().once()

    @recordData()

  prisoners: ->
    prisoners = []
    for citizen in @citizens
      if citizen.imprisoned()
        prisoners.push citizen
    prisoners

  actives: ->
    actives = []
    for citizen in @citizens
      if citizen.active
        actives.push citizen
    actives

  micros: ->
    []

  cops: ->
    @cops.length

  tickData: ->
    citizens = @citizens.length
    actives = @actives().length
    micros = @micros().length
    prisoners = @prisoners().length

    return {
      citizens: citizens
      actives: actives
      micros: micros
      prisoners: prisoners
      passives: citizens - actives - micros - prisoners
      cops: @cops.length
    }

  resetData: ->
    @data = {
      passives: [], actives: [], prisoners: [], cops: [], micros: [],
      media: []
    }
    
  recordData: ->
    ticks = @animator.ticks
    tickData = @tickData()

    #@data.passives.push [ticks, tickData.passives]
    @data.actives.push [ticks, tickData.actives]
    @data.prisoners.push [ticks, tickData.prisoners]
    @data.cops.push [ticks, tickData.cops]
    @data.micros.push [ticks, tickData.micros]

  recordMediaChange: ->
    @data.media.push [ticks, 0], [ticks, @citizens.length], null

  consoleLog: ->
    console.log 'Config:'
    console.log @config
    console.log 'Calibration:'
    console.log '  Arrest Probability:'

    for count in [
        {cops: 0, actives: 1},
        {cops: 1, actives: 1}, {cops: 2, actives: 1}, {cops: 3, actives: 1},
        {cops: 1, actives: 4}, {cops: 2, actives: 4}, {cops: 3, actives: 4}
      ]
      console.log @citizens[0].calculatePerceivedArrestProbability(count)

    console.log 'Citizens:'
    console.log @citizens
    console.log 'Cops:'
    console.log @cops

#class MM.Initializer extends MM.ModelSimple
class MM.Initializer extends MM.Model
  @initialize: (@config) ->
    @config ?= new MM.Config
    return new MM.Initializer(u.merge(@config.modelOptions, {config: @config}))
    #return new MM.Initializer(@config) TODO
  
  startup: ->
    @media = new MM.Media(this)
    unless @isHeadless
      @views = new MM.Views(this)
      window.modelUI = new MM.UI(this)

  setup: ->
    @agents.setUseSprites() # Bitmap for better performance.
    @animator.setRate 20, false
    super()
