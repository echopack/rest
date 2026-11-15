#!/bin/sh
# Regenerate the example's generated code: carbon's tables and relations,
# then rest's mappings and encoders. Both read the module through echoc, so
# run carbongen first: restgen's pass compiles .carbon/.
#
#   scripts/gen.sh [check]
set -e
cd "$(dirname "$0")/.."
command=${1:-generate}
CARBONGEN=${CARBONGEN:-../../../carbon/cli/ecobuild/carbongen}
RESTGEN=${RESTGEN:-../../cli/ecobuild/restgen}
"$CARBONGEN" "$command"
"$RESTGEN" "$command"
