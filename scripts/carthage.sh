#!/bin/bash
# carthage.sh

# shellcheck disable=SC1091
# shellcheck source=exclude-architectures.sh
. "$(dirname "$0")/exclude-architectures.sh"

"$CARTHAGE_BIN_PATH" "$@"
