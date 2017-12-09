#!/bin/sh

echo "deploy! $TRAVIS_TAG"
if [ $TRAVIS_TAG -ne '' ]; then
    echo "deploy really! $TRAVIS_TAG"
fi
