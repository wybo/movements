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
