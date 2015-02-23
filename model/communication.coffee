class MM.Communication
  constructor: (model, options = {}) ->
    @model = model

    @media = new ABM.Array

    @media[MM.MEDIA.none] = new MM.None(@model.config.mediaModelOptions)
    @media[MM.MEDIA.forum] = new MM.Forum(@model.config.mediaModelOptions)
    @media[MM.MEDIA.website] = new MM.Website(@model.config.mediaModelOptions)
    @media[MM.MEDIA.email] = new MM.EMail(@model.config.mediaModelOptions)

    @updateOldMedium()

  medium: ->
    @media[@model.config.medium]

  oldMedium: ->
    @media[@model.config.oldMedium]

  updateOldMedium: ->
    @model.config.oldMedium = @model.config.medium
