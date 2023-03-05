#!/usr/bin/env sh

set -euf

rake db:reset
rake knapsack:rspec
