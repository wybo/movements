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
  }
  div = $("#content")
  div2 = $('<div>').css({ float: 'left', clear: 'left' })
  div.append(div2)
  label = test.setup.label || ''
  div2.append('<p>Experiment run: ' + label + '</p>')
  div2 = $('<div>').css({ float: 'left', clear: 'left' })
  div.append(div2)
  data = []

  for key, variable of config.ui
    if key != 'media' and key != 'micros'
      if (test.data[key])
        data.push({label: variable.label, color: variable.color, data: test.data[key]})

  space = $('<div>').css({
    'width' : '2096px', 'height' : '1048px', 'float' : 'left', 'margin-right' : '0.7em',
    'margin-bottom' : '1em'
  })
  # 'width' : '300px', 'height' : '160px', 'float' : 'left', 'margin-right' : '0.7em',
  div2.append(space)

  $.plot(space, data, options)

window.setupDropdown = (optionSelect, options, defaultOption) ->
  for option, i in options
    $(optionSelect).append(
      '<option value="' + i + '"' +
      (defaultOption == i ? ' selected="selected"' : '') + '>' +
      option + '</option>')
