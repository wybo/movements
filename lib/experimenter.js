set_experiment = function(selector) {
  var key = selector.selectedIndex;
  fetch_and_plot_experiment(key);
};

// rather than $.getScript, to circumvent Chrome local origin issue
fetch_and_plot_experiment = function(key) {
  var old,
      head,
      script;
  old = document.getElementById('uploadScript');  
  if (old !== null) {  
    old.parentNode.removeChild(old);  
  } 
  head = document.getElementsByTagName("head")[0]; 
  script = document.createElement('script');
  script.id = 'uploadScript';
  script.type = 'text/javascript';
  script.onload = plot_experiment; 
  script.src = 'runs/' + experiments[key];
  head.appendChild(script);  
};

plot_experiment = function() {
  var i;
  div = $("#content");
  div.html('');
  console.log(experiment);
//  _display_note(div, experiment[0].config);
  for(i = 0; i < experiment.length; i++) {
    plot_test(experiment[i], i);
  }
//  _display_costs_benefits(div, experiment[0].config);
};

plot_test = function(test, index) {
  var keys = ["passives", "actives"],
      k,
      div,
      space,
      options = {
          series: { shadowSize: 0 }, // drawing is faster without shadows
          xaxis: { show: false }
      };
  div = $("#content");
  div2 = $('<div>').css({'float' : 'left', 'clear' : 'left'});
  div.append(div2);
//  _display_config(div2, test.config);
  div2.append('<p>Time until critical mass: </p>');
  div2 = $('<div>').css({'float' : 'left', 'clear' : 'left'});
  div.append(div2);
  for (i = 0; i < keys.length; i++) {
    if (test.data[keys[i]]) {
      space = $('<div>').css({'width' : '300px', 'height' : '160px', 'float' : 'left', 'margin-right' : '0.7em',
          'margin-bottom' : '1em'});
      div2.append(space);
      data = [{data: test.data[keys[i]]}]
      $.plot(space, data, options);
    }
  }
};

setup_dropdown = function(option_select, options, default_option) {
  for (var i = 0; i < options.length; i++) {
    $(option_select).append(
        '<option value="' + i + '"' + (default_option == i ? ' selected="selected"' : '') + '>' + 
        options[i] + '</option>');
  }
};
