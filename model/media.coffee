class MM.Media
  constructor: (model, options = {}) ->
    @model = model

    @media = new ABM.Array

    options = u.merge(@model.config.mediaModelOptions, {config: @model.config, originalModel: @model, isHeadless: true})

    @media[MM.MEDIA.tv] = new MM.MediumTV(options)
    @media[MM.MEDIA.newspaper] = new MM.MediumNewspaper(options)
    @media[MM.MEDIA.telephone] = new MM.MediumTelephone(options)
    @media[MM.MEDIA.email] = new MM.MediumEMail(options)
    @media[MM.MEDIA.website] = new MM.MediumWebsite(options)
    @media[MM.MEDIA.forum] = new MM.MediumForum(options)
    @media[MM.MEDIA.facebookWall] = new MM.MediumFacebookWall(options)

    @adopted = new ABM.Array
    @adoptedReset() # Defines a few more adopted

  populate: ->
    for medium in @adopted
      medium.populate()

  restart: ->
    for medium in @adopted
      @medium.restart()

  once: ->
    for medium in @adopted
      medium.once()

  adoptedReset: ->
    @adoptedOld = @adopted
    @adoptedDropped = new ABM.Array
    for medium in @adoptedOld
      @adoptedDropped.push medium

    @adopted = new ABM.Array
    @adoptedAdded = new ABM.Array
    for mediumNr in @model.config.media
      if mediumNr != MM.MEDIA.none
        @adopted.push @media[mediumNr]
        @adoptedAdded.push @media[mediumNr]

    @adoptedDropped.remove(@adopted)
    @adoptedAdded.remove(@adoptedDropped)

  changed: ->
    @adoptedReset()
    for medium in @adoptedDropped
      medium.reset()
    for medium in @adoptedAdded
      medium.reset()
      medium.populate()
      medium.start()
    @model.recordMediaChange()
