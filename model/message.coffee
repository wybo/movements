class MM.Message
  constructor: (options) ->
    @from = options.from
    @to = options.to
    @active = options.active
    @readers = new ABM.Array
  
  destroy: ->
    for reader in @readers
      reader.die()
