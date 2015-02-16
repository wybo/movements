class Communication
  constructor: (model, options = {}) ->
    @model = model

    @media = new ABM.Array

    @media[ABM.MEDIA.none] = new None(@model.config.mediaModelOptions)
    @media[ABM.MEDIA.forum] = new Forum(@model.config.mediaModelOptions)
    @media[ABM.MEDIA.website] = new Website(@model.config.mediaModelOptions)
    @media[ABM.MEDIA.email] = new EMail(@model.config.mediaModelOptions)

    @updateOldMedium()

  medium: ->
    @media[@model.config.medium]

  oldMedium: ->
    @media[@model.config.oldMedium]

  updateOldMedium: ->
    @model.config.oldMedium = @model.config.medium
