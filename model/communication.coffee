class Communication
  constructor: (model, options = {}) ->
    @model = model

    medium_hash = {
      div: "media"
      patchSize: 20
      min: {x: 0, y: 0}
      max: {x: 19, y: 19}
    }

    @media = new ABM.Array
    @media[ABM.MEDIA.forum] = new Forum(medium_hash)
    @media[ABM.MEDIA.website] = new Website(medium_hash)
    @media[ABM.MEDIA.email] = new EMail(medium_hash)

    @model.config.oldMedium = @model.config.medium

  medium: ->
    @media[@model.config.medium]

  oldMedium: ->
    @media[@model.config.oldMedium]

  updateOldMedium: ->
    @model.config.oldMedium = @model.config.medium
