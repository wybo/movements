class MM.MediumTV extends MM.MediumGenericBroadcast
  setup: ->
    super

  createAgent: (original) ->
    agent = super(original)

    agent.step = ->
      if u.randomInt(50) == 1
        @model.newMessage(@)
      
      @toNextReading()

    agent.toNextReading = (countIt) ->
      @read(@channel[0], countIt)
