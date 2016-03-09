class MM.MediumFacebookWall extends MM.MediumGenericDelivery
  setup: ->
    super

  use: (original) ->
    agent = super(original)

    agent.step = ->
      if u.randomInt(10) == 1
        @newPost() # TODO move newPost to agent

      @toNextReading()

    agent.newPost = ->
      me = @
      friends = @model.agents.sample(size: 15, condition: (o) ->
        me.original.isFriendsWith(o.original) and me.id != o.id
      )
      friends.concat(@model.agents.sample(size: 30 - friends.length, condition: (o) ->
        me.id != o.id
      ))

      for friend in friends
        @model.newMessage(@, friend)
