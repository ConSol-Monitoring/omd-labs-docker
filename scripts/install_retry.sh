#!/usr/bin/env bash

# Script to retry commands with configurable retry count and delay
# Usage: install_retry.sh -r <retries> -d <delay> -- <command> [args...]

RETRIES=3
DELAY=5
COMMAND=()

# parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -r)
      RETRIES="$2"
      shift 2
      ;;
    -d)
      DELAY="$2"
      shift 2
      ;;
    --)
      shift
      COMMAND=("$@")
      break
      ;;
    *)
      echo "unknown option: $1" >&2
      echo "usage: $0 -r <retries> -d <delay> -- <command> [args...]" >&2
      exit 1
      ;;
  esac
done

attempt=1
while [[ $attempt -le $((RETRIES + 1)) ]]; do
  if [[ $attempt -gt 1 ]]; then
    echo "*** attempt $attempt of $((RETRIES + 1))"
  fi

  if "${COMMAND[@]}"; then
    if [[ $attempt -gt 1 ]]; then
      echo "*** command succeeded on attempt $attempt"
    fi
    exit 0
  else
    exit_code=$?
    echo "*** command failed on attempt $attempt with exit code $exit_code"

    if [[ $attempt -le $RETRIES ]]; then
      echo "*** waiting $DELAY seconds before retry..."
      sleep "$DELAY"
      ((attempt++))
    else
      echo "*** all attempts exhausted. Command failed."
      exit $exit_code
    fi
  fi
done
