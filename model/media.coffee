class MM.Media
  constructor: (model, options = {}) ->
    @model = model

    @media = new ABM.Array

    @media[MM.MEDIA.none] = new MM.MediumNone(@model.config.mediaModelOptions)
    @media[MM.MEDIA.email] = new MM.MediumEMail(@model.config.mediaModelOptions)
    @media[MM.MEDIA.website] = new MM.MediumWebsite(@model.config.mediaModelOptions)
    @media[MM.MEDIA.forum] = new MM.MediumForum(@model.config.mediaModelOptions)
    @media[MM.MEDIA.facebook_wall] = new MM.MediumFacebookWall(@model.config.mediaModelOptions)

    @updateOld()

  current: ->
    @media[@model.config.medium]

  old: ->
    @media[@model.config.oldMedium]

  updateOld: ->
    @model.config.oldMedium = @model.config.medium
