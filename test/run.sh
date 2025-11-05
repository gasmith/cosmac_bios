#!/bin/bash

set -euo pipefail

usage() {
  echo "$0 usage:" && grep " .)\ #" "$0"
  exit "$1"
}
duration=5s
while getopts "i:e:t:" arg; do
  case $arg in
  i) # Binary, required
    image=$OPTARG
    ;;
  t) # Run duration with units
    duration=$OPTARG
    ;;
  h) # Help
    usage 0
    ;;
  *)
    usage 1
    ;;
  esac
done

[ "${image-}" != "" ] || usage 1
base=$(basename "${image%.bin}")
output=$base-output.evlog
expect=$base-expect.evlog
input=$base-input.evlog
args=(
  "run"
  "--ram" "$image"
  "--duration" "$duration"
  "--output-events" "$output"
)
if [ -f "$input" ]; then
  args+=(
    "--input-events" "$input"
  )
fi
cosmac_emu "${args[@]}"
touch "$expect"
diff -u "$expect" "$output"
rm "$output"
