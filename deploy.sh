#!/bin/sh

echo "deploy! $NACHOS"
if [ "$TRAVIS_TAG" != "" ]; then
    echo "deploy really! $TRAVIS_TAG"
fi
