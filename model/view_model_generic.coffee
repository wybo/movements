class MM.ViewGeneric extends MM.ViewModel
  populate: ->
    @config.genericViewPopulate.call(@)

  step: ->
    @config.genericViewStep.call(@)
