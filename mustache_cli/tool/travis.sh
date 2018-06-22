#!/usr/bin/env bash

set -xe

dartanalyzer bin lib test
pub run test -p vm