class MM.Agent extends ABM.Agent
  constructor: ->
    super

    @mediumMirrors = new ABM.Array # TODO move to model
    @viewMirrors = new ABM.Array # TODO move to model

  mediumMirror: ->
    @mediumMirrors[@model.config.medium]

  setColor: (color) ->
    @color = new u.color color
    @sprite = null

  moveToRandomEmptyLocation: ->
    @moveTo(@model.patches.sample((patch) -> patch.empty()).position)

  randomEmptyNeighbor: ->
    @patch.neighbors(@vision).sample((patch) -> patch.empty())
