#!/bin/bash
set -e

# logging functions
write_log() {
  local type="$1"; shift
  printf '%s [%s] [Entrypoint]: %s\n' "$(date --rfc-3339=seconds)" "$type" "$*"
}
log_info() {
  write_log Info "$@"
}
log_warn() {
  write_log Warn "$@" >&2
}
log_error() {
  write_log ERROR "$@" >&2
  exit 1
}

# Verify that the minimally required password settings are set for new databases.
docker_verify_minimum_env() {
  if [[ -z "$SENDY_FQDN" || -z "$MYSQL_HOST" || -z "$MYSQL_USER" || -z "$MYSQL_PASSWORD" || -z "$MYSQL_DATABASE" ]]; then
    log_error $'Environment variables not initialized!!'
  fi
}

apache2_check_config() {
  local toRun=( "$@" -t ) errors
  if ! errors="$("${toRun[@]}" 2>&1 >/dev/null)"; then
    log_error $'Apache2 failed while attempting to check config\n\tcommand was: '"${toRun[*]}"$'\n\t'"$errors"
  else
    log_info "Apache2 runtime configurations: OK"
  fi
}

log_info "Entrypoint script for Sendy Server ${SENDY_VERSION} started."

# if command starts with an option, prepend php
if [ "${1:0:1}" = '-' ]; then
log_info "Command-line option found.  Appending 'php'. "
set -- php "$@"
fi

# skip setup if we are not running apache2
if [ "$1" = 'apache2-foreground' ]; then
# Ensure apache config syntax is correct.
apache2_check_config "$@"
docker_verify_minimum_env
log_info "Starting Apache2"
# Start cron
cron -f &
log_info "Starting cron"
exec "$@"
else
log_info "Command-line override.  Executing: $@"
exec "$@"
fi
