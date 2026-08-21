#!/bin/sh
# Managed by this repository.
# Check if authenticated (exit 0) or unauthenticated (exit 1)
gh auth status >/dev/null 2>&1
