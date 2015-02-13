#! /bin/bash

export THEOS_DEVICE_IP=localhost

export THEOS_DEVICE_PORT=55555


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

kill -9 $(ps aux | grep '[t]cprelay.py' | awk '{print $2}')

$DIR/SSH-Tunneling/tcprelay.py -t 22:55555 &

make package messages=yes install

kill -9 $(ps aux | grep '[t]cprelay.py' | awk '{print $2}')

exit 0