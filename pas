#!/bin/sh
#
# pas: a password manager
# depends on age(1)
#
# by yury; in the public domain

usage() {
  printf 'usage: %s [service] [login]\n' "${0##*/}"
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


enc() {
  age --encrypt --output "$password_path" --recipient "$rec"
}


enter_password() {
  mkdir -p "$service_path"
  if ask_yesno 'generate password?'; then
    password="$(generate_password)"
  else
    type_password password
    type_password password2 ' (again)'
    # shellcheck disable=2154 
    [ "$password" = "$password2" ] || die 'passwords do not match.'
  fi
  [ "$password" ] || die 'failed to generate a password.'
  printf '%s' "$password" | enc
}


type_password() {
  log "enter$2: "
  stty -echo
  read -r "$1"
  stty echo
  printf '\n'
}


generate_password() {
  LC_ALL=C tr -dc "${PAS_PATTERN:-_A-Z-a-z-0-9}" </dev/urandom |
    dd ibs=1 obs=1 count="${PAS_LEN:-50}" 2>/dev/null
}


ask_yesno() {
  log "$1 [y/N] "
  stty -icanon
  yn=$(dd ibs=1 count=1 2>/dev/null)
  stty icanon
  printf '\n'
  case "$yn" in [yY]) return 0 ;; esac
  return 1
}


show_password() {
  [ -f "$password_path" ] ||
    die "${service}/${login} is not present."

  key="$(age --decrypt "$key_path" || exit 1)"

  printf '%s' "$key" | age --decrypt --identity - --output - "$password_path"
  printf '\n'
}


init() {
  # set service and login variables
  : "${service:=${1##*://}}"
  : "${login:=${2:-_}}"

  # set service and login paths
  : "${service_path:=${PAS_DIR}/${service}}"
  : "${password_path:=${service_path}/${login}.age}"
}


main() {
  # create password store
  mkdir -p "${PAS_DIR:=$HOME/my/pas}" ||
    die 'could not create password store.'

  # check if password store is accessible
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

  read -r rec < "$rec_path"

  case "$1" in
  '') usage ;;
  *)
    init "$@"
    if [ -f "$password_path" ]; then
      show_password
    else
      enter_password
    fi
  ;;
  esac
}


set +x # disable debug mode
set -f # disable globbing

main "$@"
