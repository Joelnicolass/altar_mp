#!/bin/sh
echo -ne '\033c\033]0;Docker Server\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/DockerServer.arm64.x86_64" "$@"
