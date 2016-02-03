class MM.MediumEMail extends MM.MediumGenericDelivery
  setup: ->
    super

  use: (original) ->
    agent = super(original)

    agent.step = ->
      if u.randomInt(3) == 1
        @newMessage(@, @model.agents.sample())
        
      @toNextMessage()
