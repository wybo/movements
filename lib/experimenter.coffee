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
  div = $("#content")
  div.append('<p>')
  for test, i in experiment
    label = test.setup.label || ''
    div.append(i + ': ' + label + '<br/>')
  div.append('</p>')

  window.experiment = experiment

  for i in [0...experiment.length]
    #from = 210
    #if i >= from and i < from + 10
      window.plotTest(i)

window.plotTest = (index) ->
  div = $("#content")
  div2 = $('<div>').css({ float: 'left', clear: 'left' })
  div.append(div2)
  label = window.experiment[index].setup.label || ''
  div2.append('<p class="title">Ex run: <b>' + label + '</b></p>')

  ignoreKeys = {label: true, config: true, modelOptions: true, viewModelOptions: true, mediaModelOptions: true, mediaMirrorModelOptions: true, ui: true, hashes: true}
  div2.append(window.stringifySettings(window.experiment[index].setup, ignoreKeys, window.experiment[index].setup.config, '<b>', '</b>'))
  div2.append('<br />')
  div2.append(window.stringifySettings(window.experiment[index].setup.config, ignoreKeys, window.experiment[index].setup.config, '', ''))
  div2.append('<br />')
  graphId = 'graph_' + index
  div2.append('<select id="' + graphId + '_select" onchange="reGraphTest(this)" style="margin-bottom: 0.5em;"></select> ')
  select_options = [0...window.experiment[index].fullData.length]
  select_options.push("avg")
  setupDropdown('#' + graphId + '_select', select_options, window.experiment[index].fullData.length)

  div2.append(window.stringifySettings(window.experiment[index].stats, ignoreKeys, window.experiment[index].setup.config, '', ''))

  window.graphTest(window.experiment[index].data, index, window.experiment[index].setup.config)

window.reGraphTest = (selector) ->
  index = parseInt(selector.id.split('_')[1])
  sub_index = selector.selectedIndex
  if sub_index == window.experiment[index].fullData.length
    window.graphTest(window.experiment[index].data, index, window.experiment[index].setup.config)
  else
    window.graphTest(window.experiment[index].fullData[sub_index], index, window.experiment[index].setup.config)

window.graphTest = (testData, index, config) ->
  div = $("#content")
  graphId = 'graph_' + index
  old = document.getElementById(graphId)
  if old != null
    old.parentNode.removeChild(old)

  options = {
    series: { shadowSize: 0 }, # drawing is faster without shadows
    grid: { markings: [] }
  }

  div2 = $('<div id="' + graphId + '">').css({ float: 'left', clear: 'left' })
  div.append(div2)
  data = []

  got_keys = []
  for key, variable of config.ui
    if (testData[key])
      got_keys.push(key)
      if key == 'cops'
        data.push({label: variable.label, color: variable.color, dashes: { show: true }, data: testData[key]})
      else
        data.push({label: variable.label, color: variable.color, data: testData[key]})
  
  for key in got_keys
    if (testData[key + "_b"])
      data.push({id: key + "_b", data: testData[key + "_b"], lines: { show: true, lineWidth: 0, fill: false }, color: config.ui[key].color})
    if (testData[key + "_t"])
      data.push({id: key + "_t", data: testData[key + "_t"], lines: { show: true, lineWidth: 0, fill: 0.2 }, color: config.ui[key].color, fillBetween: key + "_b"})

  for marking in testData["media"]
    options.grid.markings.push { color: "#000", lineWidth: 2, xaxis: { from: marking.ticks, to: marking.ticks } }

  options.series['lines'] = options.series['dashes'] = { lineWidth: 5 }
  options['axisLabels'] = { show: true }
  options['xaxis'] = { font: { size: 28, color: '#666' } }
  #xticksx = []
  #for i in [0..25]
  #  xticksx.push([i * 52, 1990 + i])
  #options['xaxis'] = { font: { size: 28, color: '#666' }, ticks: xticksx }
  options['xaxes'] = [{ axisLabel: 'Ticks', axisLabelPadding: 30 }]
  #options['xaxes'] = [{ axisLabel: 'Years', axisLabelPadding: 30 }]
  options['yaxis'] = { min: 0, max: 150, font: { size: 28, color: '#666' } }
  #yticksy = []
  #for i in [1..7]
  #  if i > 3
  #    yticksy.push([2 ** i, ((10 ** (i - 1)) / 1000) + 'k'])
  #options['yaxis'] = { min: 0, max: 150, font: { size: 28, color: '#666' }, ticks: yticksy }
  options['yaxes'] = [{ axisLabel: 'Citizens', axisLabelPadding: 30 }]
  options['dashes'] = { show: true }

  space = $('<div>').css({
    'width' : '2096px', 'height' : '1048px', 'float' : 'left'
  })
  # 'width' : '300px', 'height' : '160px', 'float' : 'left', 'margin-right' : '0.7em',
  div2.append(space)

  $.plot(space, data, options)
  $("#content div.legend td.legendLabel").css({'font-size' : '2.2em'})
  $("#content div.legend td.legendColorBox div div").css('border-width' : '1em 1.5em 1em 1.5em')
  $("#content div.legend td.tickLabel").css('font-size' : '1.5em')
  $("#content div.axisLabels").css({'font-size' : '2.2em'})
  $("#content div.xaxisLabel").css({'margin-top' : '-30px'})

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
    if defaultOption == i
      selected = ' selected'
    else
      selected = ''
    $(optionSelect).append('<option value="' + i + '"' + selected + '>' + option + '</option>')
