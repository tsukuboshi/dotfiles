#!/bin/bash

BLUE_UTIL_PATH=$(which blueutil)

# Add sleep script
echo "$BLUE_UTIL_PATH -p 0" > ~/.sleep
chmod 777 ~/.sleep

# Add wakeup script
echo "$BLUE_UTIL_PATH -p 1" > ~/.wakeup
chmod 777 ~/.wakeup

# Restart sleepwatcher
if [ "$(which sleepwatcher)" != "" ]; then
  brew services restart sleepwatcher
else
  echo "Install sleepwatcher using brew to start the service."
fi
