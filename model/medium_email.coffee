class MM.MediumEMail extends MM.MediumGenericDelivery
  setup: ->
    super

  createAgent: (original) ->
    agent = super(original)

    agent.step = ->
      if u.randomInt(3) == 1
        @model.newMessage(@, @model.agents.sample())
        
      @readInbox()
