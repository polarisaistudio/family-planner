#!/bin/bash
# Wrapper that fixes plugin registrant after Flutter generates it

# Run the original Flutter build script
/bin/sh "$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh" "$@"

# Fix the generated plugin registrant
cd "$(dirname "$0")/.."
./fix_ios_plugins.sh

exit 0
