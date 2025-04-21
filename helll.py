#!/usr/bin/env bash
source /opt/ros/noetic/setup.bash
source /ASCC_CONTAINER/devel/setup.bash
if [ $# -gt 0 ];then
    # If we passed a command, run it
    exec "$@"
else
    /bin/bash
fi
