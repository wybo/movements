class MM.MediumFacebookWall extends MM.MediumGenericDelivery
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
      friends = @model.agents.sample(size: 30, condition: (o) ->
        me.original.isFriendsWith(o.original) and me.id != o.id
      )
      if friends.length < 30
        friends.concat(@model.agents.sample(size: 30 - friends.length, condition: (o) ->
          me.id != o.id
        ))

      for friend in friends
        @model.newMessage(@, friend)
