#!/usr/bin/env bash

set -xe

pushd mustache
pub get
tool/travis.sh
popd

pushd mustache_fs
pub get
tool/travis.sh
popd
