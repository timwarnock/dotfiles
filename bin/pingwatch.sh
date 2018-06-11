#!/bin/bash
##
#
#
##


DEST=google.com

ping -nUW1 $DEST | unbuffer -p awk -F'[ =]' '{ print int($10) }' | unbuffer -p printHIST.sh
