class MM.Message
  constructor: (from, to) ->
    @from = from
    @to = to
    @active = @from.original.active
    @activism = @from.original.activism
    @readers = new ABM.Array
  
  destroy: ->
    for reader in @readers
      reader.die()
