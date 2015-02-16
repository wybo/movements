class Agent extends ABM.Agent
  constructor: ->
    super

    @twins = new ABM.Array

  twin: ->
    @twins[@model.config.medium]

  setColor: (color) ->
    @color = new u.color color
    @sprite = null

  moveToRandomEmptyLocation: ->
    @moveTo(@model.patches.sample((patch) -> patch.empty()).position)

  randomEmptyNeighbor: ->
    @patch.neighbors(@vision).sample((patch) -> patch.empty())
