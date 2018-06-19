#!/usr/bin/env bash

set -xe

dartanalyzer lib test
pub run test -p vm