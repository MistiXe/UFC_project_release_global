#!/bin/sh
printf '\033c\033]0;%s\a' champollion_fighter
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Champollion_fighter_v0.7.3.x86_64" "$@"
