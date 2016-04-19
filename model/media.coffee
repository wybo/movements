class MM.Media
  constructor: (model, options = {}) ->
    @model = model

    @media = new ABM.Array

    options = u.merge(@model.config.mediaModelOptions, {config: @model.config, originalModel: @model})
    #mirrorOptions = u.merge(@model.config.mediaMirrorModelOptions, {config: @model.config, originalModel: @model})

    @media[MM.MEDIA.none] = new MM.MediumNone(options)
    @media[MM.MEDIA.tv] = new MM.MediumTV(options)
    @media[MM.MEDIA.newspaper] = new MM.MediumNewspaper(options)
    @media[MM.MEDIA.telephone] = new MM.MediumTelephone(options)
    @media[MM.MEDIA.email] = new MM.MediumEMail(options)
    @media[MM.MEDIA.website] = new MM.MediumWebsite(options)
    @media[MM.MEDIA.forum] = new MM.MediumForum(options)
    @media[MM.MEDIA.facebookWall] = new MM.MediumFacebookWall(options)

    @updateOld()

  current: ->
    @media[@model.config.medium]

  allOffline: ->
    for medium in @media
      medium.onlineTimer = 0

  old: ->
    @media[@model.config.oldMedium]

  updateOld: ->
    @model.config.oldMedium = @model.config.medium

  changed: ->
    @old().reset()
    @current().reset() # TODO eval
    @current().populate()
    @current().start()
    @model.recordMediaChange()
    @updateOld()
