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
