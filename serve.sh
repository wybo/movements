#/usr/bin/bash

./copy.sh &
./build.sh &
echo "http://0.0.0.0:8000"
python http-server.py 8000
