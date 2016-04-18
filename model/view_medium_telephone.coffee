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

