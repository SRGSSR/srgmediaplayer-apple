#!/bin/bash

# This script attempts to install the local ruby version if not installed.

REPOSITORY_FOLDER=$1

if [[ -z "${REPOSITORY_FOLDER}" ]]; then
    echo "A repository folder must be provided."
    exit 1
fi

RUBY_VERSION=$(cat "${REPOSITORY_FOLDER}/.ruby-version")

if [[ -z "${RUBY_VERSION}" ]]; then
    echo "A local ruby version must be provided in .ruby-version file. See rbenv local command."
    exit 1
fi

if ! rbenv versions | grep "${RUBY_VERSION}" &> /dev/null; then
    echo "Need to install Ruby ${RUBY_VERSION}."
    rbenv install "${RUBY_VERSION}"
    echo "Ruby ${RUBY_VERSION} now installed."
else 
    echo "Ruby ${RUBY_VERSION} already installed."
fi