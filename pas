#!/bin/sh
#
# pas: a password manager
# depends on age(1)
#
# by yury; in the public domain

usage() {
  printf 'usage: %s [service name] [secret name]
  service name - name of your password bucket, e.g. "github.com" or "github.com/username"
  secret name  - _ for passwords by default but can be "totp" or "login"\n' "${0##*/}"
  exit 0
}

log() {
  printf '\033[0;3%sm%s\033[0m %s' \
    "${3:-0}" "${2:->}" "$1" >&2
}

die() {
  log "$1" 'ERROR' '1'
  printf '\n'
  exit 1
}

enter_secret() {
  mkdir -p "$service_path"
  if ask_yn 'generate password?'; then
    pw="$(generate_pw)"
  else
    type_pw pw
    type_pw pw2 ' (again)'
    # shellcheck disable=2154 
    [ "$pw" = "$pw2" ] || die 'passwords do not match.'
  fi
  [ "$pw" ] || die 'failed to generate a password.'

  read -r rec < "$rec_path"
  printf '%s' "$pw" |
    age --encrypt --output "$secret_path" --recipient "$rec"
}

type_pw() {
  log "enter$2: "
  stty -echo
  read -r "$1"
  stty echo
  printf '\n'
}

generate_pw() {
  LC_ALL=C tr -dc "${PAS_PATTERN:-_A-Z-a-z-0-9}" </dev/urandom |
    dd ibs=1 obs=1 count="${PAS_LEN:-50}" 2>/dev/null
}

ask_yn() {
  log "$1 [y/N] "
  stty -icanon
  yn=$(dd ibs=1 count=1 2>/dev/null)
  stty icanon
  printf '\n'
  case "$yn" in [yY]) return 0 ;; esac
  return 1
}

show_secret() {
  : "${cleartext_path:=${service_path}/${secret_name}.txt}"

  if ! pgrep -x sleep > /dev/null; then
    rm -f "$cleartext_path"
  fi

  if [ ! -s "$cleartext_path" ]; then
    age --decrypt "$key_path" |
      age --decrypt --identity - --output "$cleartext_path" "$secret_path"

    {
      sleep "${PAS_TIMEOUT:-120}" || kill 0
      rm -f "$cleartext_path"
    } &
  fi

  read -r cleartext < "$cleartext_path"
    
  printf '%s\n' "$cleartext"
}

main() {
  # disable debug mode
  set +x

  # disable globbing
  set -f

  # create a password store store
  mkdir -p "${PAS_DIR:=$HOME/my/pas}" ||
    die 'could not create password store.'

  # check if the password store is accessible
  cd "$PAS_DIR" ||
    die 'could not access directory.'
  
  # restrict permissions of any new files to only the current user
  umask 077

  # leave terminal usable after exit or Ctrl+C
  [ -t 1 ] &&
    trap 'stty echo icanon' INT EXIT

  # set a key
  [ -f "${key_path:=${PAS_DIR}/.key.age}" ] || {
    key="$(age-keygen)"
    printf '%s' "$key" | age -p > "${key_path}"
  }

  # set a recepient
  [ -f "${rec_path:=${PAS_DIR}/.rec}" ] || {
    [ -z "$key" ] && {
      key="$(age -d "${key_path}")"
    }
    printf '%s' "$key" | age-keygen -y > "$rec_path"
  }

  # set secret and service variables
  : "${service_name:=${1##*://}}"
  : "${secret_name:=${2:-_}}"

  # set service and secret paths
  : "${service_path:=${PAS_DIR}/${service_name}}"
  : "${secret_path:=${service_path}/${secret_name}.age}"

  if [ -f "$secret_path" ]; then
    show_secret
  else
    enter_secret
  fi
}

case "$1" in
'') usage     ;;
* ) main "$@" ;;
esac
