#!/bin/sh
# Managed by this repository.
# Prompt redraws must not contact GitHub. This reports credential availability,
# not token validity; run gh auth status explicitly to validate the login.
if [ "${STARSHIP_GH_LIVE_CHECK:-off}" = on ]; then
  gh auth status >/dev/null 2>&1
else
  gh auth token >/dev/null 2>&1
fi
