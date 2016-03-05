class MM.MediumFacebookWall extends MM.MediumGenericDelivery
  setup: ->
    super

  use: (original) ->
    agent = super(original)

    agent.step = ->
      if u.randomInt(10) == 1
        @model.newPost(@) # TODO move newPost to agent

      @toNextReading()

  newPost: (agent) ->
    friends = @agents.sample(size: 30, condition: (o) ->
      agent.original.isFriendsWith(o.original)
    )

    for friend in friends
      @newMessage(agent, friend)
