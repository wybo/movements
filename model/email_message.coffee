class EmailMessage extends Message
  constructor: (options) ->
    super(options)
    @to = options.to
