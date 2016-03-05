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
  script.src = 'experiments/' + experiments[key]
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
    grid: { markings: [] }
  }
  div = $("#content")
  div2 = $('<div>').css({ float: 'left', clear: 'left' })
  div.append(div2)
  label = test.setup.label || ''
  div2.append('<p class="title">Experiment run: <b>' + label + '</b></p>')

  ignoreKeys = {label: true, config: true, modelOptions: true, viewModelOptions: true, mediaModelOptions: true, mediaMirrorModelOptions: true, ui: true, hashes: true}
  console.log test.setup
  div2.append(window.stringifySettings(test.setup, ignoreKeys, test.setup.config, '<b>', '</b>'))
  div2.append('<br />')
  div2.append(window.stringifySettings(test.setup.config, ignoreKeys, test.setup.config, '', ''))

  div2 = $('<div>').css({ float: 'left', clear: 'left' })
  div.append(div2)
  data = []

  for key, variable of config.ui
    if (test.data[key])
      data.push({label: variable.label, color: variable.color, data: test.data[key]})

  for marking in test.data["media"]
    console.log marking
    options.grid.markings.push { color: "#000", lineWidth: 1, xaxis: { from: marking.ticks, to: marking.ticks } }

  space = $('<div>').css({
    'width' : '2096px', 'height' : '1048px', 'float' : 'left', 'margin-right' : '0.7em',
    'margin-bottom' : '1em'
  })
  # 'width' : '300px', 'height' : '160px', 'float' : 'left', 'margin-right' : '0.7em',
  div2.append(space)

  $.plot(space, data, options)

# modifies ignoreKeys
window.stringifySettings = (hash, ignoreKeys, config, open = '', close = '') ->
  settings = []
  for key, value of hash
    if !ignoreKeys[key]
      if ABM.util.isArray(value)
        settings.push open + key + ': [' + window.stringifySettings(value, {"_sort": true}, config) + ']' + close
      else if ABM.util.isObject(value)
        settings.push open + key + ': {' + window.stringifySettings(value, {"_sort": true}, config) + '}' + close
      else
        settings.push window.stringifySetting(key, value, config, open, close)
      ignoreKeys[key] = true

  return settings.join(', ')

window.stringifySetting = (key, value, config, open, close) ->
  stringified = window.stringifyHashSetting(key, value, open, close, config)
  
  if stringified
    return stringified
  else
    return open + key + ': ' + value.toString() + close

window.stringifyHashSetting = (key, value, open, close, config) ->
  for keyConfig, valueConfig of config.hashes
    if keyConfig == key
      return open + key + ': ' + window.decodeHash(valueConfig, value) + close
  return null

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
