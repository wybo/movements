#/usr/bin/bash

function copyAll {
  cp /home/wybo/projects/agentbase/agentbase/lib/agentbase.coffee lib/agentbase.coffee
  cp /home/wybo/projects/agentbase/agentbase/lib/agentbase.js lib/agentbase.js
  cp /home/wybo/projects/agentbase/agentbase/lib/agentbase.map lib/agentbase.map
}

copyAll

while ./tools/sleep_until_modified.py /home/wybo/projects/agentbase/agentbase/lib/agentbase.js
do 
  copyAll
done
