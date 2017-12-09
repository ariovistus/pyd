#!/bin/sh

echo "deploy! $NACHOS"
if [ "$NACHOS" == "tacos" ]; then
    echo "deploy really! $TRAVIS_TAG"
fi
