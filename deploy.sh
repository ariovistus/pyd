#!/bin/sh

echo "deploy! $PWD"
if [ "$TRAVIS_TAG" != "" ]; then
    echo "deploy really! $TRAVIS_TAG"
fi
