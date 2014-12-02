#/usr/bin/bash

function copyAll {
  cp /home/wybo/projects/agentbase/agentbase/lib/agentbase.coffee javascripts/agentbase.coffee
  cp /home/wybo/projects/agentbase/agentbase/lib/agentbase.js javascripts/agentbase.js
  cp /home/wybo/projects/agentbase/agentbase/lib/agentbase.map javascripts/agentbase.map
}

copyAll

while sleep_until_modified.py /home/wybo/projects/agentbase/agentbase/lib/agentbase.js
do 
  copyAll
done
