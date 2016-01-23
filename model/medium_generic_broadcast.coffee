class MM.MediumGenericBroadcast extends MM.Medium
  setup: ->
    super

    @channels = new ABM.Array

    for n in [0..7]
      @newChannel(n)

  createAgent: (original) ->
    agent = super

    if !agent.channel
      agent.channel = @channels[u.randomInt(@channels.length)]

    return agent

  newChannel: (number) ->
    newChannel = new ABM.Array

    newChannel.number = number

    newChannel.report = (report) ->
      report.previous = @last()
      if report.previous?
        report.previous.next = report
  
      report.channel = @
  
      @push(report)

      if @length > report.from.model.world.max.y + 1
        report = @shift()

        for reader, index in report.readers by -1
          reader.read(report.next)
        
        report.destroy()

    newChannel.destroy = ->
      for report in @
        report.destroy() # takes readers as well

    @channels.unshift newChannel

    if @channels.length > @world.max.x + 1
      throw "Too many channels for world size"

  newReport: (from) ->
    @route new MM.Message from

  route: (report) ->
    report.from.channel.report report

  drawAll: ->
    @copyOriginalColors()
    @resetPatches()

    for channel, i in @channels
      #x = i % (@world.max.x + 1)
      for report, j in channel
        patch = @patches.patch(x: i, y: j)
        @colorPatch(patch, report)

    for agent, i in @agents
      x = agent.channel.number

      agent.moveTo x: x, y: 0
