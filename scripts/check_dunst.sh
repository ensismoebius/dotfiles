#!/bin/bash

COUNT=$(dunstctl count waiting)

if [ "$COUNT" -gt 0 ]; then
  echo " $COUNT"
else
  echo ""
fi
