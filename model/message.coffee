class MM.Message
  constructor: (from, to) ->
    @from = from
    @to = to
    @readers = new ABM.Array

    if MM.MEDIUM_TYPES.totalCensorship == @from.config.mediumType
      @active = false
      @activism = 0
    else if MM.MEDIUM_TYPES.uncensored == @from.config.mediumType
      status = @from.original.calculateActiveStatus(@from.original.grievance())
      @active = status.active
      @activism = status.activism

      #if @from.original.sawArrest # TODO fix/improve
      #  @active = true
      #  @activism = 1
    else if MM.MEDIUM_TYPES.micro == @from.config.mediumType
      @active = @from.original.active
      @activism = @from.original.micro
    else
      @active = @from.original.active
      @activism = @from.original.activism

    #@arrest = @from.original.sawArrest TODO fix/improve

  destroy: ->
    for reader in @readers by -1
      reader.toNextReading(false)
