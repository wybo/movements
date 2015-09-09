class MM.MediumFacebookWall extends MM.MediumGenericDelivery
  setup: ->
    super

  step: ->
    for agent in @agents
      if u.randomInt(3) == 1
        @newPost(agent)
      else
        agent.readPosts()

    @drawAll()

  use: (original) ->
    agent = @createAgent(original)
    agent.readPosts = ->
      for post in @inbox
        agent.read(post)

      @inbox.clear()

  newPost: (agent) ->
    friends = @agents.sample(size: 30, condition: (o) ->
      agent.original.isFriendsWith(o.original)
    )

    for friend in friends
      @newMessage(agent, friend)
