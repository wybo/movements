class MM.MediumFacebookWall extends MM.MediumGenericDelivery
  setup: ->
    super

  step: ->
    for agent in @agents by -1
      if u.randomInt(3) == 1
        @newPost(agent)

      agent.readPosts()

    @drawAll()

  use: (original) ->
    agent = @createAgent(original)

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
