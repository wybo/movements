Movements Model
==============

This is a simple ABM of the effect of the Internet on social movement
formation. 

I am developing it as part of my thesis.

Different social mechanisms and media platforms will be added over time.

You can always find the latest working version in this repository, and
a [live demo on AgentBase here](http://agentbase.org/model.html?7b745fe0c641aca3cd1d)
[and here](http://wybowiersma.net/movements/)

Installation
--------------

There is no need to install anything if you just want to run 
or edit the model. Just copy it to a webserver and access index.html.
Read on if you want to just open index.html.

It you want to edit it, it's best to run it locally. This because
changes in files in the model directory need to be appended into 
model.coffee before they take effect.

When using locally on your machine, you'll need to use a webserver 
to prevent *browser security errors*. For this it requires python 
SimpleHTTPServer and npm to 'npm install' the dependencies. Then run 
the local webserver with ./serve.sh, and visit it at
http://0.0.0.0:8000

If you want to make changes to the AgentBase library as well, you 
will need to remove the lib/agentbase.js file, and then get the 
latest version of AgentBase with:

    git clone git@github.com:wybo/agentbase.git
    cd agentbase
    npm install

Then check it's docs on how to compile changes, in agentbase/README.md,
make your changes, and after compiling, copy agentbase/lib/agentbase.js
to lib/agentbase.js.
