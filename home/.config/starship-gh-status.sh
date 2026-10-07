#!/bin/sh
# Managed by this repository.
# Check local credentials without contacting GitHub during prompt redraws.
# Run gh auth status explicitly to validate token expiry.
if [ "${STARSHIP_GH_LIVE_CHECK:-off}" = on ]; then
  gh auth status >/dev/null 2>&1
else
  gh auth token >/dev/null 2>&1
fi
