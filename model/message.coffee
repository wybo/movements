class MM.Message
  constructor: (from, to) ->
    @from = from
    @to = to
    @readers = new ABM.Array

    if MM.MEDIUM_TYPES.uncensored == @from.original.config.mediumType
      status = @from.original.calculateActiveStatus(@from.original.grievance())
      @active = status.active
      @activism = status.activism
    else
      @active = @from.original.active
      @activism = @from.original.activism
  
  destroy: ->
    for reader in @readers by -1
      reader.toNextMessage()
