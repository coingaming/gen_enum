#!/bin/bash

set -e

docker exec -it $(docker ps | grep "gen_enum_main" | awk '{print $1;}') /app/scripts/remote-iex.sh
