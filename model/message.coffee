class MM.Message
  constructor: (from, to) ->
    @from = from
    @to = to
    @readers = new ABM.Array
    @from.config.setMessageStatus.call(@)

  destroy: ->
    for reader in @readers by -1
      reader.toNextReading(false)
