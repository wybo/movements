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
