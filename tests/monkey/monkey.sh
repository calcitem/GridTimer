#!/bin/bash

# Android Monkey Test Script for GridTimer
# This script runs random UI stress testing on the GridTimer app
# Should be run with the app built in test environment (--dart-define=test=true)

PLATFORM_TOOLS=~/AppData/Local/Android/Sdk/platform-tools

if [ "$(uname)" == "Darwin" ]; then
    PLATFORM_TOOLS=~/Library/Android/sdk/platform-tools
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    PLATFORM_TOOLS=~/Android/sdk/platform-tools
fi

cd ${PLATFORM_TOOLS} || exit

# Monkey test parameters:
# -v: verbose output
# -p: package name (GridTimer)
# --pct-touch 50: 50% touch events
# --pct-motion 50: 50% motion events (drag/swipe)
# --pct-trackball 0: 0% trackball events (not applicable)
# --pct-nav 0: 0% navigation events
# --pct-majornav 0: 0% major navigation events (back/menu)
# --pct-syskeys 0: 0% system keys (home/volume)
# --pct-anyevent 0: 0% other events
# --throttle 500: 500ms delay between events
# 10000000: total number of events to generate

./adb shell monkey -v -p com.calcitem.gridtimer --pct-touch 50 --pct-motion 50 --pct-trackball 0 --pct-nav 0 --pct-majornav 0 --pct-syskeys 0 --pct-anyevent 0 --throttle 500 10000000

