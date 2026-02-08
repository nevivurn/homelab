#!/usr/bin/env bash
set -euo pipefail

ssh vyos@"$1" /opt/vyatta/bin/vyatta-op-cmd-wrapper show configuration commands | tr -d '"'"'" | LC_ALL=C sort
