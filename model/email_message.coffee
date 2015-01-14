class Message
  ## Class variables & methods

  @inboxes = new ABM.Array

  @read: (agent) ->
    @inboxes[agent.twin.id].pop()

  @inbox: (agent) ->
    @inboxes[agent.twin.id] ||= new ABM.Array
    @inboxes[agent.twin.id]

  ## Variables & methods

  constructor: (options) ->
    super(options)
    @to = options.to
    @route()

  route: ->
    @constructor.inboxes[@to.twin.id].push @
