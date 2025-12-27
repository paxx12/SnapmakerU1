# shellcheck shell=sh disable=SC1091,SC2039,SC2166
# Add /usr/local/bin to PATH if that directory exists

[ -d /usr/local/bin ] && export PATH="/usr/local/bin:$PATH"
