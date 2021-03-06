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

MM.TYPES = u.indexHash(["normal", "enclave", "focalPoint", "activesAdvance", "square"])
MM.SUPPRESSION = u.indexHash(["normal", "micro", "fearless"])
MM.CALCULATIONS = u.indexHash(["real", "epstein", "wilensky", "overwhelmed", "overpowered"])
MM.LEGITIMACY_CALCULATIONS = u.indexHash(["normal", "activism", "evidence"])
MM.FRIENDS = u.indexHash(["none", "random", "cliques", "local"])
MM.MEDIA = u.indexHash(["none", "tv", "newspaper", "telephone", "email", "website", "forum", "blog", "facebookWall", "twitter"])
MM.MEDIUM_CENSORSHIP = u.indexHash(["normal", "uncensored", "totalCensorship", "micro"])
MM.VIEWS = u.indexHash(["none", "riskAversion", "hardship", "grievance", "regimeLegitimacy", "arrestProbability", "netRisk", "follow"].concat(u.deIndexHash(MM.MEDIA).remove("none")))
# turn back to numbers once dat.gui fixed

class MM.Config
  constructor: ->
    @testRun = false
    @type = MM.TYPES.normal
    @suppression = MM.SUPPRESSION.normal
    @calculation = MM.CALCULATIONS.real
    @legitimacyCalculation = MM.LEGITIMACY_CALCULATIONS.normal
    @friends = MM.FRIENDS.none
    #@media = new ABM.Array MM.MEDIA.website
    @media = new ABM.Array MM.MEDIA.none
    @mediumCensorship = MM.MEDIUM_CENSORSHIP.normal
    #@view = MM.VIEWS.regimeLegitimacy
    #@view = MM.VIEWS.riskAversion
    #@view = MM.VIEWS.website
    @view = MM.VIEWS.none
    @smartPhones = false

    @riskAversionDistributionNormal = false
    @hardshipDistributionNormal = false
    
    @synchronizeProtest = false # hold off
    @coordinateProtest = false # build up to, while hiding
    @notifyOfProtest = false # require notifications for either of the above
    @protestCycle = 150 # for the two above
    @protestDuration = 50 # for the two above

    @copsRetreat = false
    @copsDefect = false
    #@prisonCapacity = 0.10
    @prisonCapacity = 1.00

    @friendsNumber = 30 # also used for Fb
    @friendsMultiplier = 2 # 1 actively cancels out friends
    @friendsHardshipHomophilous = false # If true range has to be 6 min, and friends max 30 or will have fewer
    @friendsRiskAversionHomophilous = false # If true range has to be 6 min, and friends max 30 or will have fewer
    @friendsLocalRange = 6
    @friendsRevealFearless = false # Towards friends signal as if there are no cops around. Uncensored for this on media

    @mediaOnlineTime = 5
    @mediaAverageReceiveNr = 5 # TODO: Nr of messages that agents should receive on average on every tick; false for media-dependent
    @mediaMaxReadNr = false # Max nr of messages that should be counted every tick; false for unlimited
    @mediaRiskAversionHomophilous = false
    @mediaOnlyNonRiskAverseUseMedia = false # Nullifies effect of mediaRiskAversionHomophilous, as all media users risk hungry
    @mediaChannels = 7 # for media TV and radio

    @citizenDensity = 0.7
    #@copDensity = 0.04
    #@copDensity = 0.012
    @copDensity = 0.03
    #@arrestDuration = 2
    @arrestDuration = 0
    @maxPrisonSentence = 30 # J
    #@baseRegimeLegitimacy = 0.85 # L
    #@baseRegimeLegitimacy = 0.70 # L
    #@baseRegimeLegitimacy = 0.66 # best with arrest delay 2 + friends etc
    @baseRegimeLegitimacy = 0.56 # best with base
    @threshold = 0.1
    @thresholdMicro = 0.0
    #@vision = {diamond: 7} # Neumann 7, v and v*
    @vision = {radius: 7} # Neumann 7, v and v*
    @walk = {radius: 2} # Neumann 7, v and v*
    @kConstant = 2.3 # k

    @warmupPeriod = 0 # Time in ticks before charting / cops defect, etc

    @ui = {
      #      passives: {label: "Passives", color: "green"},
      actives: {label: "Actives", color: "red"},
      #micros: {label: "Micros", color: "orange"},
      #arrests: {label: "Arrests", color: "purple"},
      prisoners: {label: "Prisoners", color: "black"},
      cops: {label: "State Actors", color: "blue"}
      #onlines: {label: "Onlines", color: "cyan"}
    }

    # ### Do not modify below unless you know what you're doing.

    @hashes = {
      type: MM.TYPES,
      suppression: MM.SUPPRESSION,
      calculation: MM.CALCULATIONS,
      legitimacyCalculation: MM.LEGITIMACY_CALCULATIONS,
      friends: MM.FRIENDS,
      medium: MM.MEDIA,
      mediumCensorship: MM.MEDIUM_CENSORSHIP,
      view: MM.VIEWS
    }

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

    @mediaModelOptions = {
      patchSize: 10
      min: {x: 0, y: 0}
      max: {x: 39, y: 39}
    }

    @config = @

    @setFunctions()
    @check()

  makeHeadless: ->
    @modelOptions.isHeadless = true

    @check()

  setFunctions: ->
    # ### Defaults
    
    @colorPatch = (patch) ->
      patch.color = u.color.random type: "gray", min: 224, max: 255

    @riskAversionDistribution = ->
      return u.randomFloat()

    @hardshipDistribution = ->
      return u.randomFloat()

    @regimeLegitimacy = ->
      return @config.baseRegimeLegitimacy

    @citizenArrestProbability = (count) ->
      if count.cops > count.activism
        return 1
      else
        return count.cops / count.activism

    @copWillMakeArrestProbability = (count) ->
      return 1

    @move = ->
      @moveToRandomEmptyNeighbor(@config.walk)

    @moveAndArrest = ->
      @config.initiateArrest.call(@)
      @moveToRandomEmptyNeighbor()

    @initiateArrest = ->
      protester = @neighbors(@config.vision).sample(condition: (agent) ->
        agent.breed.name is "citizens" and agent.active)

      if protester
        protester.imprison()

    @moveOffIfOnline = ->
      if @online()
        if @position
          @moveOff()
      else
        if !@position
          @moveToRandomEmptyLocation()

    @maintainFriends = ->

    @maintainNotify = ->

    @resetAllFriends = ->

    @sampleOnlineFriend = ->
      return null

    @calculateActiveStatus = (grievance, netRisk) ->
      if grievance > @config.threshold
        fearless_activism = 1.0
      else
        fearless_activism = 0.0

      activation = grievance - netRisk

      if activation > @config.threshold
        return {micro: 1.0, activism: 1.0, fearless_activism: fearless_activism, active: true}
      else if activation > @config.thresholdMicro
        return {micro: 0.4, activism: 0.0, fearless_activism: fearless_activism, active: false}
      else
        return {micro: 0.0, activism: 0.0, fearless_activism: fearless_activism, active: false}

    @setStatus = (status) ->
      @active = status.active
      @micro = status.micro
      @activism = status.activism
      @fearless_activism = status.fearless_activism

    @setMessageStatus = ->
      @active = @from.original.active
      @activism = @from.original.activism

      if @from.original.gotEvidence
        @evidence = true

    @micros = ->
      return []

    @genericViewPopulate = ->

    @genericViewStep = ->

    @doAct = ->
      true

    @copDoAct = ->
      true

    # ### Types
    
    if MM.TYPES.enclave == @type
      @colorPatch = (patch) ->
        if patch.position.y > 0
          patch.color = u.color.random type: "gray", min: 180, max: 204
        else
          patch.color = u.color.random type: "gray", min: 234, max: 255

      @move = ->
        if @riskAverse
          @moveToRandomBottomHalf(@config.walk)
        else
          @moveToRandomUpperHalf(@config.walk)

    else if MM.TYPES.focalPoint == @type
      @move = ->
        if @riskAverse
          @moveAwayFromPoint(@config.walk, {x: 0, y: 0})
        else
          @moveTowardsPoint(@config.walk, {x: 0, y: 0})

    else if MM.TYPES.activesAdvance == @type
      @move = ->
        if @active
          @advance()
        else
          @moveToRandomEmptyNeighbor(@config.walk)

    else if MM.TYPES.square == @type
      @move = ->
        @moveToRandomEmptyNeighbor(@config.walk)
        if @active
          @swapToActiveSquare({x: 0, y: 0}, range: 5)

    # ### Suppression

    if MM.SUPPRESSION.micro == @suppression
      @setStatus = (status) ->
        @active = status.active
        @micro = status.micro
        @activism = status.micro # micro taken for activism
        @fearless_activism = status.fearless_activism

      @micros = ->
        micros = []
        for citizen in @citizens
          if !citizen.active and citizen.activism > 0 and
              not citizen.imprisoned()
            micros.push citizen
        return micros

    else if MM.SUPPRESSION.fearless == @suppression
      @setStatus = (status) ->
        @active = status.active
        @micro = status.micro
        @activism = status.fearless_activism # fearless_activism taken for activism
        @fearless_activism = status.fearless_activism

    # ### Calculations

    if MM.CALCULATIONS.epstein == @calculation
      @citizenArrestProbability = (count) ->
        return 1 - Math.exp(-1 * @config.kConstant * count.cops / count.activism)

    else if MM.CALCULATIONS.wilensky == @calculation
      @citizenArrestProbability = (count) ->
        return 1 - Math.exp(-1 * @config.kConstant * Math.floor(count.cops / count.activism))

    else if MM.CALCULATIONS.overwhelmed == @calculation # used for 'real' for a bit
      @copWillMakeArrestProbability = (count) ->
        overwhelm = count.cops * 7 / count.activism
        if overwhelm > 1
          return 1
        else
          return overwhelm

    else if MM.CALCULATIONS.overpowered == @calculation
      @copWillMakeArrestProbability = (count) ->
        if count.cops * 7 > count.activism
          return 1
        else
          return 0
 
    # ### Legitimacy Calculations

    if MM.LEGITIMACY_CALCULATIONS.normal != @legitimacyCalculation
      @regimeLegitimacy = ->
        if @imprisoned()
          return @config.baseRegimeLegitimacy
        else
          if @online()
            count = {}
            for medium in @mediaMirrors()
              count = u.addUp(count, medium.count)

            count.citizens = count.reads
          else
            count = @countNeighbors(vision: @config.vision)

          @lastLegitimacyDrop = (@lastLegitimacyDrop * 2 + @config.calculateLegitimacyDrop.call(@, count)) / 3

          return @config.baseRegimeLegitimacy - @lastLegitimacyDrop * 0.1

    if MM.LEGITIMACY_CALCULATIONS.activism == @legitimacyCalculation
      @calculateLegitimacyDrop = (count) ->
        if count.citizens == 0
          return 0
        else
          return count.activism / count.citizens

    if MM.LEGITIMACY_CALCULATIONS.evidence == @legitimacyCalculation
      #return count.arrests / (count.citizens - count.activism)
      # could consider taking min of cops + activism, police-violence
      # or arrests
      # Make active agents share photos of fights
      # Two things expressed. Grievance/active and photos
      @calculateLegitimacyDrop = (count) ->
        if count.citizens == 0
          return 0
        else if count.evidence > 0
          return 1
        else
          return count.activism / count.citizens

    # ### Friends

    if MM.FRIENDS.none != @friends
      @sampleOnlineFriend = ->
        me = @
        return @model.agents.sample(condition: (o) ->
            me.original.isFriendsWith(o.original) and me.id != o.id and o.online()
        )

    if MM.FRIENDS.random == @friends
      @resetAllFriends = ->
        for citizen in @citizens # 2 loops to reset old before making new
          citizen.resetFriends()

        for citizen in @citizens
          citizen.makeRandomFriends(@config.friendsNumber)

    else if MM.FRIENDS.cliques == @friends
      @resetAllFriends = ->
        for citizen in @citizens
          citizen.resetFriends()

        for citizen in @citizens
          citizen.makeCliqueFriends(@config.friendsNumber)

    else if MM.FRIENDS.local == @friends
      @maintainFriends = ->
        @makeLocalFriends(@config.friendsNumber)

      @resetAllFriends = ->
        for citizen in @citizens
          citizen.resetFriends()

        for citizen in @citizens
          citizen.makeLocalFriends(@config.friendsNumber)

    # ### Medium types (Media and Views in their classes)

    if MM.MEDIUM_CENSORSHIP.totalCensorship == @mediumCensorship
      @setMessageStatus = ->
        @active = false
        @activism = 0
        @evidence = false

    else if MM.MEDIUM_CENSORSHIP.uncensored == @mediumCensorship # Also below, friendsRevealFearless
      @setMessageStatus = ->
        @activism = @from.original.fearless_activism
        if @activism == 1.0
          @active = true
        else
          @active = false

        if @from.original.gotEvidence
          @evidence = true

    else if MM.MEDIUM_CENSORSHIP.micro == @mediumCensorship
      @setMessageStatus = ->
        @active = @from.original.active
        @activism = @from.original.micro

        if @from.original.gotEvidence
          @evidence = true

    # ### Misc settings

    if @notifyOfProtest
      @colorPatch = (patch) ->
        dark = false
        if patch.position.y % 2 == 0
          dark = true

        if patch.position.x % 2 == 0
          if dark
            dark = false
          else
            dark = true

        if dark
          patch.color = u.color.from([220, 220, 220])
        else
          patch.color = u.color.from([241, 241, 241])

      @maintainNotify = ->
        if @patch.noticeCounter
          @patch.noticeCounter -= 1
          if @patch.noticeCounter == 0
            @patch.noticeCounter = null
            @config.colorPatch(@patch)
          @notified = true

        if u.randomInt(200) == 1
          @leaveNotice()

    if @synchronizeProtest
      @calculateActiveStatus = (grievance, netRisk) ->
        bestActive = true
        bestActivism = 1.0
        if @notifyOfProtest
          if @notified
            if @model.animator.ticks % @config.protestCycle == @config.protestDuration
              @notified = false

            if @model.animator.ticks % @config.protestCycle > @config.protestDuration
              bestActive = false
              bestActivism = 0.0
        else
          if @model.animator.ticks % @config.protestCycle > @config.protestDuration
            bestActive = false
            bestActivism = 0.0

        if grievance > @config.threshold
          fearless_activism = 1.0
        else
          fearless_activism = 0.0

        activation = grievance - netRisk

        if activation > @config.threshold
          return {micro: bestActivism, activism: bestActivism, fearless_activism: fearless_activism, active: bestActive}
        else if activation > @config.thresholdMicro
          return {micro: 0.4, activism: 0.0, fearless_activism: fearless_activism, active: false}
        else
          return {micro: 0.0, activism: 0.0, fearless_activism: fearless_activism, active: false}

    if @coordinateProtest
      @calculateActiveStatus = (grievance, netRisk) ->
        bestActive = true
        if @notifyOfProtest
          if @notified
            if @model.animator.ticks % @config.protestCycle == @config.protestDuration
              @notified = false

            if @model.animator.ticks % @config.protestCycle > @config.protestDuration
              bestActive = false
        else
          if @model.animator.ticks % @config.protestCycle > @config.protestDuration
            bestActive = false

        if grievance > @config.threshold
          fearless_activism = 1.0
        else
          fearless_activism = 0.0

        activation = grievance - netRisk

        if activation > @config.threshold
          return {micro: 1.0, activism: 1.0, fearless_activism: fearless_activism, active: bestActive}
        else if activation > @config.thresholdMicro
          return {micro: 0.4, activism: 0.0, fearless_activism: fearless_activism, active: false}
        else
          return {micro: 0.0, activism: 0.0, fearless_activism: fearless_activism, active: false}

    if @copsDefect
      @moveAndArrest = ->
        count = @countNeighbors(vision: @config.vision)
        count.cops += 1

        if count.activism * 2 > count.citizens and count.cops * 10 < count.activism and @model.animator.ticks > @config.warmupPeriod
          patch = @patch
          @die()
          @model.citizens.create 1, (citizen) =>
            @model.setupCitizen(citizen)
            citizen.moveTo(patch.position)
        else
          @config.initiateArrest.call(@)
          @moveToRandomEmptyNeighbor()

    if @copsRetreat
      @moveAndArrest = ->
        if @calculateCopWillMakeArrestProbability(count) < u.randomFloat()
          @moveTowardsArrestProbability(@config.walk, @config.vision, true)
        else
          @config.initiateArrest.call(@)
          @moveToRandomEmptyNeighbor()

    if @smartPhones
      @moveOffIfOnline = ->
        if !@position
          @moveToRandomEmptyLocation()

    if @riskAversionDistributionNormal
      @riskAversionDistribution = ->
        return u.clamp(u.randomNormal(0.5, 0.5 / 3), 0, 1)
    
    if @hardshipDistributionNormal
      @hardshipDistribution = ->
        return u.clamp(u.randomNormal(0.5, 0.5 / 3), 0, 1)

    if @arrestDuration > 0
      @doAct = ->
        if @fighting()
          false
        else
          true

      @copDoAct = ->
        if @fighting()
          @arresting.beatUp()
          if !@arresting.fighting()
            @arresting.imprison()
            @arresting = null

        if @fighting()
          false
        else
          true

      @initiateArrest = ->
        protester = @neighbors(@config.vision).sample(condition: (agent) ->
          agent.breed.name is "citizens" and agent.active and !agent.fighting())

        if protester
          @arresting = protester
          @arresting.beginArrest()

    # ### Views

    if MM.VIEWS.hardship == @view
      @genericViewPopulate = ->
        MM.ViewModel.prototype.populate.call(this) # super
        for citizen in @citizens
          citizen.color = u.color.red.fraction(citizen.original.hardship)
        for cop in @cops
          cop.color = cop.original.color

    else if MM.VIEWS.riskAversion == @config.view
      @genericViewPopulate = ->
        MM.ViewModel.prototype.populate.call(this) # super
        for citizen in @citizens
          citizen.color = u.color.red.fraction(citizen.original.riskAversion)
        for cop in @cops
          cop.color = cop.original.color

    else if MM.VIEWS.none != @view
      @genericViewPopulate = ->
        MM.ViewModel.prototype.populate.call(this) # super
        for cop in @cops
          cop.color = cop.original.color

    if MM.VIEWS.arrestProbability == @config.view
      @genericViewStep = ->
        MM.ViewModel.prototype.step.call(this) # super
        for citizen in @citizens
          citizen.color = u.color.red.fraction(citizen.original.arrestProbability())

    else if MM.VIEWS.netRisk == @config.view
      @genericViewStep = ->
        MM.ViewModel.prototype.step.call(this) # super
        for citizen in @citizens
          citizen.color = u.color.red.fraction(citizen.original.netRisk())

    else if MM.VIEWS.regimeLegitimacy == @config.view
      @genericViewStep = ->
        MM.ViewModel.prototype.step.call(this) # super
        for citizen in @citizens
          citizen.color = u.color.red.fraction(citizen.original.regimeLegitimacy())

    else if MM.VIEWS.grievance == @config.view
      @genericViewStep = ->
        MM.ViewModel.prototype.step.call(this) # super
        for citizen in @citizens
          citizen.color = u.color.red.fraction(citizen.original.grievance())

    else if MM.VIEWS.none != @view
      @genericViewStep = ->
        MM.ViewModel.prototype.step.call(this) # super

  check: ->
    if @media.length > 0
      @medium = @media.first()
    else
      @medium = MM.MEDIA.none

    if @testRun && @modelOptions.isHeadless
      throw "Cannot be a testRun if headless"

    if @synchronizeProtest and @coordinateProtest
      throw "SynchronizeProtest and coordinateProtest incompatible, overlap"

    if @notifyOfProtest and !@synchronizeProtest and !@coordinateProtest
      throw "Notify meaningless without either set"

    if @copsDefect and @copsRetreat
      throw "CopsDefect and copsRetreat cannot both be set!"

    if @friendsMultiplier < 1
      throw "FriendsMultiplier should be 1 (cancels) or over"

    if @arrestDuration < 1 and MM.LEGITIMACY_CALCULATIONS.evidence == @legitimacyCalculation
      throw "Arrests need to be violent for legitimacyCalculation to be based on brutality evidence"

    if @mediaChannels > @mediaModelOptions.max.x + 1
      throw "Too many channels for world size"

    for index in [@type, @suppression, @calculation, @legitimacyCalculation, @friends, @medium, @mediumCensorship, @view]
      if !u.isInteger(index)
        throw "Config index " + index + " not integer!"

class MM.Message
  constructor: (from, to) ->
    @from = from
    @to = to
    @readers = new ABM.Array
    @from.config.setMessageStatus.call(@)

  destroy: ->
    for reader in @readers by -1
      reader.toNextReading(false)

# Copyright 2014, Wybo Wiersma, available under the GPL v3
# This model builds upon Epsteins model of protest, and illustrates
# the possible impact of social media on protest formation.

Function::property = (property) ->
  for key, value of property
    Object.defineProperty @prototype, key, value

class MM.Medium extends ABM.Model
  setup: ->
    @size = 0.6

    @mirrors = []

    @dummyAgent = {
      original: {active: false, activism: 0.0, grievance: (->), calculateActiveStatus: (-> @), config: @config}
      config: @config
      read: (->)
      dummy: true
    }

    for patch in @patches.create()
      patch.color = u.color.white

  populate: ->
    for original in @originalModel.agents
      if original.breed.name == "citizens"
        @createAgent(original)

  access: (original) ->
    agent = @mirrors[original.id]

    if !agent # Agents replacing defected cops are new
      agent = @createAgent(original)

    agent.onlineTimer = @config.mediaOnlineTime # activates medium

    return agent

  step: ->
    for agent in @agents by -1
      if agent.online()
        agent.resetCount()
        agent.step()

      agent.onlineTimer -= 1

    @drawAll()

  createAgent: (original) ->
    agent = @agents.create(1).last()
    agent.config = @config
    agent.original = original
    @mirrors[original.id] = agent

    agent.size = @size
    agent.heading = u.degreesToRadians(270)
    agent.color = original.color
    # agent.count below

    agent.online = ->
      @onlineTimer > 0

    agent.read = (message, countIt = true) ->
      if @config.mediaMaxReadNr and @count.reads > @config.mediaMaxReadNr
        countIt = false

      @closeMessage()

      if message and countIt
        message.readers.push(@)
        @count.reads += 1
        if message.active
          @count.actives += 1
        @count.activism += message.activism
        if message.evidence
          @count.evidences += 1

      @reading = message

    agent.closeMessage = ->
      if @reading
        @reading.readers.remove(@)

      @reading = null

    agent.resetCount = ->
      @count = {reads: 0, actives: 0, activism: 0, evidences: 0}

    agent.resetCount()

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

  drawAll: ->

class MM.MediumGenericDelivery extends MM.Medium
  setup: ->
    super

    @inboxes = new ABM.Array

  createAgent: (original) ->
    agent = super(original)

    if !agent.inbox
      agent.inbox = @inboxes[agent.original.id] = new ABM.Array

    agent.readInbox = ->
      while @inbox.length > 0
        @toNextReading()

    agent.toNextReading = (countIt) ->
      message = @inbox.shift()
      if message
        @read(message, countIt)

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

class MM.Media
  constructor: (model, options = {}) ->
    @model = model

    @media = new ABM.Array

    options = u.merge(@model.config.mediaModelOptions, {config: @model.config, originalModel: @model, isHeadless: true})

    @media[MM.MEDIA.tv] = new MM.MediumTV(options)
    @media[MM.MEDIA.newspaper] = new MM.MediumNewspaper(options)
    @media[MM.MEDIA.telephone] = new MM.MediumTelephone(options)
    @media[MM.MEDIA.email] = new MM.MediumEMail(options)
    @media[MM.MEDIA.website] = new MM.MediumWebsite(options)
    @media[MM.MEDIA.forum] = new MM.MediumForum(options)
    @media[MM.MEDIA.facebookWall] = new MM.MediumFacebookWall(options)
    @media[MM.MEDIA.twitter] = new MM.MediumTwitter(options)

    @adopted = new ABM.Array
    @adoptedReset() # Defines a few more adopted

  populate: ->
    for medium in @adopted
      medium.populate()

  restart: ->
    for medium in @adopted
      medium.restart()

  once: ->
    for medium in @adopted
      medium.once()

  adoptedReset: ->
    @adoptedOld = @adopted
    @adoptedDropped = new ABM.Array
    for medium in @adoptedOld
      @adoptedDropped.push medium

    @adopted = new ABM.Array
    @adoptedAdded = new ABM.Array
    for mediumNr in @model.config.media
      if mediumNr != MM.MEDIA.none
        @adopted.push @media[mediumNr]
        @adoptedAdded.push @media[mediumNr]

    @adoptedDropped.remove(@adopted)
    @adoptedAdded.remove(@adoptedDropped)

  changed: ->
    @adoptedReset()
    for medium in @adoptedDropped
      medium.reset()
    for medium in @adoptedAdded
      medium.reset()
      medium.populate()
      medium.start()
    @model.recordMediaChange()

class MM.MediumEMail extends MM.MediumGenericDelivery
  setup: ->
    super

  createAgent: (original) ->
    agent = super(original)

    agent.step = ->
      if u.randomInt(3) == 1
        @model.newMessage(@, @model.agents.sample())
        
      @readInbox()

class MM.MediumFacebookWall extends MM.MediumGenericDelivery
  setup: ->
    super

  createAgent: (original) ->
    agent = super(original)

    agent.step = ->
      if u.randomInt(10) == 1
        @newPost()

      @readInbox()

    agent.newPost = ->
      me = @
      friends = @model.agents.sample(size: 30, condition: (o) ->
        me.original.isFriendsWith(o.original) and me.id != o.id
      )
      if friends.length < 30
        friends.concat(@model.agents.sample(size: 30 - friends.length, condition: (o) ->
          me.id != o.id
        ))

      for friend in friends
        @model.newMessage(@, friend)

class MM.MediumForum extends MM.Medium
  setup: ->
    super

    @threads = new ABM.Array

    @newThread(@dummyAgent)
    @dummyAgent.reading = @threads[0][0]

    while @threads.length <= @world.max.x
      @newPost(@dummyAgent)

  createAgent: (original) ->
    agent = super(original)

    agent.step = ->
      if u.randomInt(10) == 1
        @model.newPost(@)

      @toNextReading()

    agent.toNextReading = (countIt) ->
      if @reading and @reading.thread.next?
        @read(@reading.thread.next.first(), countIt)
      else
        @read(@model.threads[0][0], countIt)

      tries = 0
      while @reading.active != @original.active and tries < 10 and
          (!@config.mediaRiskAversionHomophilous or @original.riskAverse == @reading.riskAverse)
        if @reading.thread.next?
          @read(@reading.thread.next.first(), false)
        else
          @read(@model.threads[0][0], false)
        tries += 1

      while @reading.next?
        @read(@reading.next, countIt)

  newPost: (agent) -> # TODO move to agent
    if u.randomInt(10) == 1
      @newThread(agent)
    else
      @newComment(agent)

  newThread: (agent) -> # TODO same
    newThread = new ABM.Array
    if @config.mediaRiskAversionHomophilous
      newThread.riskAverse = agent.original.riskAverse
    
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

class MM.MediumGenericBroadcast extends MM.Medium
  setup: ->
    super

    @channels = new ABM.Array

    for n in [0..@config.mediaChannels]
      @newChannel(n)

  createAgent: (original) ->
    agent = super(original)

    if !agent.channel
      if @config.mediaRiskAversionHomophilous # TODO finish for other media as well
        agent.channel = @channels.sample(condition: (o) -> o.riskAverse == agent.riskAverse)
      else
        agent.channel = @channels[u.randomInt(@channels.length)]

    return agent

  newChannel: (number) ->
    newChannel = new ABM.Array
    if @config.mediaRiskAversionHomophilous
      newChannel.riskAverse == false
      if number % 2 == 0
        newChannel.riskAverse == true

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

  newMessage: (from) ->
    @route new MM.Message from

  route: (message) ->
    message.from.channel.message message

class MM.MediumNewspaper extends MM.MediumGenericBroadcast
  setup: ->
    super

  createAgent: (original) ->
    agent = super(original)

    agent.step = ->
      if u.randomInt(20) == 1
        @model.newMessage(@)
      
      @toNextReading()

    agent.toNextReading = (countIt) ->
      reading = @reading
      if @channel.length == 1
        @read(@channel[0])
      else
        for [1..5]
          @read(@channel.sample(condition: (o) -> o != reading), countIt)

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

class MM.MediumTelephone extends MM.Medium
  setup: ->
    super

  createAgent: (original) ->
    agent = super(original)

    agent.step = ->
      if !@reading
        if u.randomInt(3) == 1
          @call()

      if @initiated_call
        if @timer < 0
          @disconnect()
        @timer -= 1

    agent.call = ->
      me = @ # taken into closure
      agent = null # needed or may keep previous' use
      if u.randomInt(3) < 2 # 2/3rd chanche
        agent = @config.sampleOnlineFriend.call(@)
      agent ?= @model.agents.sample(condition: (o) -> me.id != o.id and o.online())

      agent.disconnect()

      @timer = 5
      @initiated_call = true

      @read(new MM.Message agent, @)
      agent.read(new MM.Message @, agent)

    agent.disconnect = ->
      if @reading
        for reader in @reading.readers
          reader.closeMessage()
          reader.timer = 0
          reader.initiated_call = false

        @closeMessage()
        @timer = 0 # for disconnect due to offline
        @initiated_call = false

    agent.toNextMessage = ->
      # No need to always call

      #  drawAll: ->
      #    @copyOriginalColors()
      #    @resetPatches()
      #
      #    for agent in @agents
      #      if agent.original.position # Not jailed
      #        agent.moveTo(agent.original.position)
      #        if agent.reading
      #          patch = @patches.patch(agent.position)
      #          @colorPatch(patch, agent.reading)

class MM.MediumTV extends MM.MediumGenericBroadcast
  setup: ->
    super

  createAgent: (original) ->
    agent = super(original)

    agent.step = ->
      if u.randomInt(50) == 1
        @model.newMessage(@)
      
      @toNextReading()

    agent.toNextReading = (countIt) ->
      @read(@channel[0], countIt)

class MM.MediumTwitter extends MM.MediumGenericDelivery
  setup: ->
    super

  createAgent: (original) ->
    agent = super(original)

    agent.step = ->
      if u.randomInt(10) == 1
        @newPost()

      @readInbox()

    agent.newPost = ->
      me = @
      if !@followers
        @followers = @model.agents.sample(size: 30, condition: (o) ->
          me.id != o.id
        )
      # TODO consider adding selection for risk-avoidance, birds of a
      # feather.

      for follower in @followers
        @model.newMessage(@, follower)

class MM.MediumWebsite extends MM.Medium
  setup: ->
    super

    @sites = new ABM.Array
    @readNr = 5 # TODO consider making global

    while @sites.length < 100
      @newPage(@dummyAgent)

  createAgent: (original) ->
    agent = super(original)

    agent.step = ->
      if u.randomInt(20) == 1
        @model.newPage(@)

      for [1..@readNr]
        @toNextReading()

    agent.toNextReading = (countIt) ->
      @read(@model.sites.sample(), countIt)

  newPage: (agent) ->
    @sites.unshift new MM.Message agent

    if @sites.length > 100
      site = @sites.pop()
      site.destroy()

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
    dropdownHashes = {}
    for key, value of @model.config.hashes
      dropdownHashes[key] = [value]

    settings = u.merge dropdownHashes, {
      riskAversionDistributionNormal: null
      hardshipDistributionNormal: null
      smartPhones: null
      synchronizeProtest: null
      coordinateProtest: null
      notifyOfProtest: null
      protestCycle: {min: 0, max: 500}
      protestDuration: {min: 0, max: 250}
      citizenDensity: {min: 0, max: 1}
      copDensity: {min: 0, max: 0.10}
      maxPrisonSentence: {min: 0, max: 1000}
      baseRegimeLegitimacy: {min: 0, max: 1}
      threshold: {min: -1, max: 1}
      thresholdMicro: {min: -1, max: 1}
      prisonCapacity: {min: 0, max: 1}
      copsRetreat: null
      copsDefect: null
      friendsNumber: null
      friendsMultiplier: {min: 0, max: 5}
      friendsHardshipHomophilous: null
      friendsRevealFearless: null
      friendsLocalRange: 5
      mediaRiskAversionHomophilous: null
      mediaOnlyNonRiskAverseUseMedia: null
    }

    buttons =
      step: ->
        window.model.once()
      pauseResume: ->
        window.model.toggle()
      restart: ->
        window.model.restart()

    for key, value of settings
      if u.isArray(value)
        if key == "view"
          adder = @gui.add(@model.config, key, value...).listen()
        else
          adder = @gui.add(@model.config, key, value...)
        adder.onChange(@setDropdown(key, @))
      else
        adder = @gui.add(@model.config, key)
        for setting, argument of value
          adder[setting](argument)
        adder.onChange(@set(key, @))

    for key, bull of buttons
      @gui.add(buttons, key)

  set: (key, ui) -> return (value) -> # closure-fu to keep key
    ui.model.set(key, value)

  setDropdown: (key, ui) -> return (value) -> # closure-fu to keep key
    ui.model.set(key, parseInt(value))
    intValue = parseInt(value)
    if key == "medium"
      ui.model.set("view", MM.VIEWS[u.deIndexHash(MM.MEDIA)[intValue]])

  resetPlot: ->
    options = {
      series: {
        shadowSize: 0
      } # faster without shadows
      yaxis: {
        min: 0
      }
      grid: {
        markings: []
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

# Copyright 2014, Wybo Wiersma, available under the GPL v3
# This model builds upon Epsteins model of protest, and illustrates
# the possible impact of social media on protest formation.

class MM.View extends ABM.Model
  setup: ->
    # Improves performance
    @agents.setUseSprites() # Bitmap for better performance.
    @animator.setRate 20, false

    @agentBreeds ["citizens", "cops"]
    @patches.create()

  populate: ->
    for original in @originalModel.agents
      @createAgent(original)

  step: ->
    for patch in @patches
      patch.color = u.color.white

  createAgent: (original) ->
    if original.breed.name == "citizens"
      @citizens.create 1
    else
      @cops.create 1

    agent = @agents.last()
    agent.original = original

    agent.size = @size
    agent.shape = @shape
    agent.heading = u.degreesToRadians(270)

# Copyright 2014, Wybo Wiersma, available under the GPL v3
# This model builds upon Epsteins model of protest, and illustrates
# the possible impact of social media on protest formation.

class MM.ViewMedium extends MM.View
  setup: ->
    @size = 0.6
    @shape = "default"
    super

  step: ->
    super

    for agent in @agents
      agent.original.mirror = agent # mirror is only available in media views
      if agent.original.online()
        agent.color = agent.original.original.color # via medium to model, then color
      else
        agent.moveOff()

  colorPatch: (patch, message) ->
    if message.arrest
      patch.color = u.color.mediumpurple
    else if message.activism == 1.0
      patch.color = u.color.salmon
    else if message.activism > 0
      patch.color = u.color.pink
    else
      patch.color = u.color.lightgray

class MM.ViewMediumForum extends MM.ViewMedium
  step: ->
    super

    for thread, i in @originalModel.threads
      for post, j in thread
        if i <= @world.max.x and j <= @world.max.y
          patch = @patches.patch x: i, y: @world.max.y - j
          @colorPatch(patch, post)
          for reader in post.readers
            if reader.online()
              reader.mirror.moveTo(patch.position)

class MM.ViewMediumGeneric extends MM.ViewMedium

class MM.ViewMediumGenericDelivery extends MM.ViewMedium
  step: ->
    super

    xOffset = yOffset = 0
    for agent, i in @agents
      x = i % (@world.max.x + 1)
      yOffset = @world.max.y - Math.floor(i / (@world.max.x + 1)) * 5

      for message, j in agent.original.inbox
        if j < 5
          patch = @patches.patch(x: x, y: yOffset - j)
          @colorPatch(patch, message)

      agent.moveTo x: x, y: yOffset

class MM.ViewMediumNewspaper extends MM.ViewMedium
  step: ->
    super

    channelStep = Math.floor(@world.max.x / (@originalModel.channels.length + 1))

    xOffset = channelStep
    for channel, i in @originalModel.channels
      for message, j in channel
        for agent, k in message.readers
          agent.mirror.moveTo x: xOffset - k, y: j

        patch = @patches.patch(x: xOffset, y: j)
        @colorPatch(patch, message)

      xOffset += channelStep

class MM.ViewMediumTelephone extends MM.ViewMedium
  step: ->
    super

    yOffset = xOffset = 0
    for agent in @agents
      if agent.original.online()
        if agent.original.initiated_call
          from_position = {x: xOffset, y: yOffset}
          to_position = {x: xOffset + 1, y: yOffset}
          agent.moveTo(from_position)
          agent.original.reading.from.mirror.moveTo(to_position)
          @colorPatch(@patches.patch(from_position), agent.original.reading)
          @colorPatch(@patches.patch(to_position), agent.original.reading.from.reading)
          yOffset += 2

          if yOffset > @world.max.y
            yOffset = 0
            xOffset += 3


class MM.ViewMediumTV extends MM.ViewMedium
  step: ->
    super

    channelStep = Math.floor(@world.max.x / (@originalModel.channels.length + 1))

    xOffset = channelStep
    for channel, i in @originalModel.channels
      message = channel[0]
      if message
        for agent, j in message.readers
          k = j - 1

          if j == 0
            agent.mirror.moveTo x: xOffset, y: 0
          else
            column_nr = Math.floor(k / (@world.max.y + 1))
            agent.mirror.moveTo x: xOffset - column_nr - 1, y: k % (@world.max.y + 1)

      for message, j in channel
        patch = @patches.patch(x: xOffset, y: j)
        @colorPatch(patch, message)

      xOffset += channelStep

class MM.ViewMediumWebsite extends MM.ViewMedium
  step: ->
    super

    for site in @originalModel.sites
      if !site.patch?
        site.patch = @patches.sample() # Tad messy, only one view per model

      @colorPatch(site.patch, site)

    for agent in @agents
      if agent.original.online()
        if agent.original.reading
          agent.moveTo(agent.original.reading.patch.position)

class MM.ViewModel extends MM.View
  setup: ->
    @size = 1.0
    @shape = "square"
    super

  step: ->
    super

    for agent in @agents
      if agent.original.position
        agent.moveTo agent.original.position
      else
        agent.moveOff()

class MM.ViewFollow extends MM.ViewModel
  populate: ->
    super

    @agent = @citizens.first()

    console.log "Selected agent for following:"
    console.log @agent

  step: ->
    super

    for agent in @agents
      agent.color = u.color.white

    for agent in @agent.neighbors(@agent.original.config.vision)
      agent.color = agent.original.color

    @agent.original.color = @agent.color = u.color.black

class MM.ViewGeneric extends MM.ViewModel
  populate: ->
    @config.genericViewPopulate.call(@)

  step: ->
    @config.genericViewStep.call(@)

class MM.Views
  constructor: (model, options = {}) ->
    @model = model

    @views = new ABM.Array

    options = u.merge(@model.config.modelOptions, {config: @model.config, originalModel: @model, div: "view"})
    mediaOptions = u.merge(@model.config.mediaModelOptions, {config: @model.config, div: "view"})

    @views[MM.VIEWS.follow] = new MM.ViewFollow(options)

    @initializeView("tv", MM.ViewMediumTV, mediaOptions)
    @initializeView("newspaper", MM.ViewMediumNewspaper, mediaOptions)
    @initializeView("telephone", MM.ViewMediumTelephone, mediaOptions)
    @initializeView("email", MM.ViewMediumGenericDelivery, mediaOptions)
    @initializeView("website", MM.ViewMediumWebsite, mediaOptions)
    @initializeView("forum", MM.ViewMediumForum, mediaOptions)
    @initializeView("facebookWall", MM.ViewMediumGenericDelivery, mediaOptions)
    @initializeView("twitter", MM.ViewMediumGenericDelivery, mediaOptions)

    # Fill in with generic view otherwise
    genericView = new MM.ViewGeneric(options)

    for key, viewNumber of MM.VIEWS
      @views[viewNumber] ?= genericView

    @updateOld()

  initializeView: (name, klass, options) ->
    options = u.merge(options, {originalModel: @model.media.media[MM.MEDIA[name]]})
    @views[MM.VIEWS[name]] = new klass(options)

  current: ->
    @views[@model.config.view]

  old: ->
    @views[@model.config.oldView]

  updateOld: ->
    @model.config.oldView = @model.config.view

  changed: ->
    @old().reset()
    @current().reset()
    @current().populate()
    @current().start()
    @updateOld()

# Copyright 2014, Wybo Wiersma, available under the GPL v3
# This model builds upon Epsteins model of protest, and illustrates
# the possible impact of social media on protest formation.

class MM.Model extends ABM.Model
  restart: ->
    @media.restart()

    unless @isHeadless
      @views.current().restart()

    super

  setup: ->
    @agentBreeds ["citizens", "cops"]
    @size = 0.9
    @resetData()

    for patch in @patches.create()
      @config.colorPatch(patch)

    space = @patches.length

    for citizen in @citizens.create @config.citizenDensity * space
      @setupCitizen(citizen)

    @config.resetAllFriends.call(@)

    for cop in @cops.create @config.copDensity * space
      @setupCop(cop)

    @media.populate()

    unless @isHeadless
      window.modelUI.resetPlot()
      @views.current().populate()
      @consoleLog()

  setupCitizen: (citizen) ->
    citizen.config = @config
    citizen.size = @size
    citizen.shape = "person"
    citizen.setColor "green"
    citizen.moveToRandomEmptyLocation()

    citizen.hardship = @config.hardshipDistribution() # H
    citizen.hardshipped = true if citizen.hardship > 0.5
    citizen.riskAversion = @config.riskAversionDistribution() # R
    citizen.riskAverse = true if citizen.riskAversion > 0.5
    citizen.lastLegitimacyDrop = 0
    citizen.active = false
    citizen.activism = 0.0
    citizen.arrestDuration = 0
    citizen.prisonSentence = 0
    citizen.gotEvidence = false

    citizen.act = ->
      # TODO make media reading read a certain nr of posts!
      @mediaTickReset()

      if @config.doAct.call(@)
        if @imprisoned()
          @prisonSentence -= 1

          if !@imprisoned()
            @moveToRandomEmptyLocation()

        if !@imprisoned() # free or just released
          @config.moveOffIfOnline.call(@)

          if @position? # free, just released, and not behind PC
            @config.move.call(@)
            @config.maintainFriends.call(@)
            @config.maintainNotify.call(@)

            @activate()
            @updateColor()

    citizen.grievance = ->
      @hardship * (1 - @regimeLegitimacy())

    citizen.regimeLegitimacy = ->
      @config.regimeLegitimacy.call(@)

    citizen.arrestProbability = ->
      count = @countNeighbors(vision: @config.vision)

      count.activism += 1
      count.citizens += 1

      if count.arrests > 0 and u.randomInt(20) == 1 # TODO adjust
        @gotEvidence = true
      else
        @gotEvidence = false

      @calculatePerceivedArrestProbability(count)

    citizen.netRisk = ->
      @arrestProbability() * @riskAversion

    citizen.imprison = ->
      @prisonSentence = 1 + u.randomInt(@config.maxPrisonSentence)
      @moveOff()
      @goOffline()

    citizen.beginArrest = ->
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
      grievance = @grievance()
      netRisk = @netRisk()
      status = @config.calculateActiveStatus.call(@, grievance, netRisk)

      @config.setStatus.call(@, status)

    citizen.updateColor = ->
      if @active
        @setColor "red"
      else
        if @activism > 0
          @setColor "orange"
        else
          @setColor "green"

  setupCop: (cop) ->
    cop.config = @config
    cop.size = @size
    cop.shape = "person"
    cop.arresting = null
    cop.setColor "blue"
    cop.moveToRandomEmptyLocation()

    cop.act = ->
      if @config.copDoAct.call(@)
        @config.moveAndArrest.call(@)

    cop.fighting = ->
      return (@arresting != null)

  step: -> # called by MM.Model.animate
    shuffled = ABM.Array.from(@agents.slice(0)).shuffle()
    # TODO if time fix. Deep copy. Can't use agents.shuffle or will lose modified push in returned array, leading to no ID's

    for agent in shuffled
      agent.act()
      if agent.breed.name is "citizens"
        for medium in @media.adopted
          if @config.mediaOnlyNonRiskAverseUseMedia
            if !agent.riskAverse and u.randomInt(10) == 1
                medium.access(agent)
          else
            if u.randomInt(20) == 1
              medium.access(agent)

    if @animator.ticks == @config.warmupPeriod
      @resetData()

    unless @isHeadless
      window.modelUI.drawPlot()

      if @animator.ticks == @config.warmupPeriod
        window.modelUI.resetPlot()

    @media.once()

    unless @isHeadless
      @views.current().once()

    @recordData()
    
    if @config.testRun
      @testStep()

  set: (key, value) ->
    if key == "medium"
      if value == "none"
        @config["media"] = new ABM.Array
      else
        @config["media"] = new ABM.Array value
    else
      @config[key] = value
    @config.check()
    @config.setFunctions() # IMPORTANT!

    if key == "view"
      @views.changed()
    else if key == "friends"
      @config.resetAllFriends.call(@)
    else if key == "medium"
      @media.changed()

  actives: ->
    actives = []
    for citizen in @citizens
      if citizen.active and not (citizen.fighting() or citizen.imprisoned())
        actives.push citizen
    return actives

  micros: ->
    return @config.micros.call(@)

  arrests: ->
    arrests = []
    for citizen in @citizens
      if citizen.fighting()
        arrests.push citizen
    return arrests

  prisoners: (reset = false) ->
    if !@prisonersCache or reset
      @prisonersCache = []
      for citizen in @citizens
        if citizen.imprisoned()
          @prisonersCache.push citizen
    return @prisonersCache

  onlines: (reset = false) ->
    if !@onlinesCache or reset
      @onlinesCache = []
      for citizen in @citizens
        if citizen.online()
          @onlinesCache.push citizen
    return @onlinesCache

  tickData: ->
    citizens = @citizens.length
    actives = @actives().length
    micros = @micros().length
    arrests = @arrests().length
    prisoners = @prisoners(true).length

    return {
      citizens: citizens
      passives: citizens - actives - micros - arrests - prisoners
      actives: actives
      micros: micros
      arrests: arrests
      prisoners: prisoners
      cops: @cops.length
      onlines: @onlines(true).length
    }

  resetData: ->
    @data = {
      passives: [],
      actives: [],
      micros: [],
      arrests: [],
      prisoners: [],
      cops: [],
      onlines: [],
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
    @data.onlines.push [ticks, tickData.onlines]

  recordMediaChange: ->
    ticks = @animator.ticks
    @data.media.push {ticks: ticks, medium: @config.oldMedium, state: false}
    @data.media.push {ticks: ticks, medium: @config.medium, state: true}
    unless @isHeadless
      window.modelUI.plotOptions.grid.markings.push {
        color: "#000", lineWidth: 1, xaxis: { from: ticks, to: ticks }
      }

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

  testSet: (key, hash, value) ->
    if key == "medium"
      @config["media"] = [value]
    else
      @config[key] = value
    console.log "Testing " + key + " " + u.deIndexHash(hash)[@config[key]]

  testAdvance: (key, hash) ->
    if @config[key] < Object.keys(hash).length - 1
      @testSet(key, hash, @config[key] + 1)
    else
      @testSet(key, hash, 0)

  testStep: ->
    if @animator.ticks % 2 == 0
      @testAdvance("calculation", MM.CALCULATIONS)
      if @config.calculation == 0
        @testAdvance("legitimacyCalculation", MM.LEGITIMACY_CALCULATIONS)

    if @animator.ticks % 20 == 0
      @testAdvance("view", MM.VIEWS)
      mediaKey = MM.MEDIA[u.deIndexHash(MM.VIEWS)[@config.view]]
      if mediaKey
        @testSet("medium", MM.MEDIA, mediaKey)
        if @config.medium == 0
          @testAdvance("mediumCensorship", MM.MEDIUM_CENSORSHIP)
        @media.changed()
      else
        @testSet("medium", MM.MEDIA, MM.MEDIA[u.array.sample(Object.keys(MM.MEDIA))])
      @views.changed()

    if @animator.ticks % 12 == 0 #TODO, errors out
      @testAdvance("friends", MM.FRIENDS)
      @config.resetAllFriends.call(@)

    if @animator.ticks > 20 * Object.keys(MM.VIEWS).length * Object.keys(MM.MEDIUM_CENSORSHIP).length
      console.log 'Test completed!'
      @stop()

#class MM.Initializer extends MM.ModelSimple
class MM.Initializer extends MM.Model
  @initialize: (config) ->
    config ?= new MM.Config
    return new MM.Initializer(u.merge(config.modelOptions, {config: config}))
  
  startup: ->
    @media = new MM.Media(this)

    unless @isHeadless
      @views = new MM.Views(this)
      window.modelUI = new MM.UI(this)

  setup: ->
    # Improves performance. Same thing set in view.
    @agents.setUseSprites() # Bitmap for better performance.
    @animator.setRate 20, false
    super
