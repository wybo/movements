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
