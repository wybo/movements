window.setExperiment = (selector) ->
  key = selector.selectedIndex
  window.fetchAndPlotExperiment(key)

# rather than $.getScript, to circumvent Chrome local origin issue
window.fetchAndPlotExperiment = (key) ->
  old = document.getElementById('uploadScript')
  if old != null
    old.parentNode.removeChild(old)
  head = document.getElementsByTagName("head")[0]
  script = document.createElement('script')
  script.id = 'uploadScript'
  script.type = 'text/javascript'
  script.onload = window.plotExperiment
  script.src = 'runs/' + experiments[key]
  head.appendChild(script)

window.plotExperiment = ->
  div = $("#content")
  div.html('')
  config = new MM.Config
  for test, i in experiment
    window.plotTest(test, i, config)

window.plotTest = (test, index, config) ->
  options = {
    series: { shadowSize: 0 }, # drawing is faster without shadows
    xaxis: { show: false }
    grid: { markings: [] }
  }
  div = $("#content")
  div2 = $('<div>').css({ float: 'left', clear: 'left' })
  div.append(div2)
  label = test.setup.label || ''
  div2.append('<p class="title">Experiment run: <b>' + label + '</b></p>')

  ignoreKeys = {label: true, config: true, modelOptions: true, viewModelOptions: true, mediaModelOptions: true, mediaMirrorModelOptions: true, ui: true}
  ignoreKeys = window.appendSettings(div2, test.setup, ignoreKeys, '<b>', '</b>')
  div2.append('<br />')
  window.appendSettings(div2, test.setup.config, ignoreKeys)

  div2 = $('<div>').css({ float: 'left', clear: 'left' })
  div.append(div2)
  data = []

  for key, variable of config.ui
    if key == 'media'
      for marking in test.data[key]
        options.grid.markings.push { color: "#000", lineWidth: 1, xaxis: { from: markings.ticks, to: markings.ticks } }
    else
      if (test.data[key])
        data.push({label: variable.label, color: variable.color, data: test.data[key]})

  space = $('<div>').css({
    'width' : '2096px', 'height' : '1048px', 'float' : 'left', 'margin-right' : '0.7em',
    'margin-bottom' : '1em'
  })
  # 'width' : '300px', 'height' : '160px', 'float' : 'left', 'margin-right' : '0.7em',
  div2.append(space)

  $.plot(space, data, options)

window.appendSettings = (div, hash, ignoreKeys, open, close) ->
  for k, v of hash
    if !ignoreKeys[k]
      window.appendSetting(div, k, v, open, close)
      ignoreKeys[k] = true

  return ignoreKeys

window.appendSetting = (div, key, value, open, close) ->
  open = open || ''
  close = close || ''
  matchedConfig = false
  configH = {type: MM.TYPES, calculation: MM.CALCULATIONS, legitimacyCalculation: MM.LEGITIMACY_CALCULATIONS, friends: MM.FRIENDS, medium: MM.MEDIA, mediumType: MM.MEDIUM_TYPES, view: MM.VIEWS}
  for kC, vC of configH
    if kC == key
      div.append(open + key + ': ' + window.decodeHash(vC, value) + close + ', ')
      matchedConfig = true
  
  if !matchedConfig
    if key == 'vision' or key == 'walk'
      div.append(open + key + ': ' + JSON.stringify(value) + close + ', ')
    else
      div.append(open + key + ': ' + value.toString() + close + ', ')

window.decodeHash = (hash, vId) ->
  for k, v of hash
    if v == vId
      return k

window.setupDropdown = (optionSelect, options, defaultOption) ->
  for option, i in options
    $(optionSelect).append(
      '<option value="' + i + '"' +
      (defaultOption == i ? ' selected="selected"' : '') + '>' +
      option + '</option>')
