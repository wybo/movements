class MM.ViewMediumForum extends MM.ViewMedium
  step: ->
    super

    for thread, i in @model.threads
      for post, j in thread
        if i <= @world.max.x and j <= @world.max.y
          patch = @patches.patch x: i, y: @world.max.y - j
          @colorPatch(patch, post)
          for reader in post.readers
            if reader.online()
              reader.mirror.moveTo(patch.position)
