# Copyright 2014, Wybo Wiersma, available under the GPL v3
# This model builds upon Epsteins model of protest, and illustrates
# the possible impact of social media on protest formation.

class MM.ViewMedium extends MM.View
  setup: ->
    @size = 0.6
    @shape = "default"
    super

  step: ->
    super

    for agent in @agents
      agent.original.mirror = agent # mirror is only available in media views
      if agent.original.online()
        agent.color = agent.original.original.color # via medium to model, then color
      else
        agent.moveOff()

  colorPatch: (patch, message) ->
    if message.arrest
      patch.color = u.color.mediumpurple
    else if message.activism == 1.0
      patch.color = u.color.salmon
    else if message.activism > 0
      patch.color = u.color.pink
    else
      patch.color = u.color.lightgray
