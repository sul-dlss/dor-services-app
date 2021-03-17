#!/usr/bin/env bash

set -e

# Quiet ruby warnings.
export RUBYOPT='-W:no-deprecated -W:no-experimental'

# Adds/updates cache for recently indexed objects.

YESTERDAY=`date -d "yesterday" --iso-8601`
bin/generate-druid-list "timestamp:[${YESTERDAY}T00:00:00Z TO NOW]" -o new_druids.txt -q
bin/generate-cache -o -i new_druids.txt -q
sort druids.txt new_druids.txt | uniq | shuf > druids.rand.txt
cp druids.rand.txt druids.txt
