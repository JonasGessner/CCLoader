#! /bin/bash

export THEOS_DEVICE_IP=iPhone # You can either save your device under the Alias 'iPhone' or place the IP of your device here

make package install

rm install