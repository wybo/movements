class Message
  @inboxes = new ABM.Array

  @read: (agent) ->
    @inboxes[agent.twin.id].pop()

  @inbox: (agent) ->
    @inboxes[agent.twin.id] ||= new ABM.Array
    @inboxes[agent.twin.id]

  constructor: (options) ->
    @from = options.from
    @to = options.to
    @active = options.active
    @route()

  route: ->
    @constructor.inboxes[@to.twin.id].push @
