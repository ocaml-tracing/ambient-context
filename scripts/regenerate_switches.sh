#!/bin/sh
# shellcheck shell=dash
set -eu

#  This script sets up opam switches and generates lockfiles.
#
#  Usage:
#     ./scripts/regenerate_switches.sh [--locked|--regen-locks]
#
#     --locked
#        Create switches and install dependencies using existing lockfiles. Does not modify
#        lockfiles.
#     --regen-locks
#        Create switches, install dependencies, and immediately regenerate lockfiles with the
#        results of those clean installations.

SWITCH_PREFIX="ambient-context"
OCAML_4_FORMULA='"ocaml-base-compiler" {>= "4.08" & < "5.0"}'
OCAML_5_FORMULA='"ocaml-base-compiler" {>= "5.0" & < "6.0"}'
export OPAMYES=1

script_name="$(basename "$0")"
puts() { printf %s\\n "$@" ;}
logs() { printf '\033[90m[%s %s]\033[0m %s\n' "$(date +%T)" "$script_name" "$*" ;}
loge() { printf '\033[91m[%s %s]\033[0m !! %s\n' "$(date +%T)" "$script_name" "$*" >&2 ;}
argq() { [ $# -gt 0 ] && printf "'%s' " "$@" ;}

if [ "$1" = "--regen-locks" ]; then
   regen_locks=true
   shift

   if [ "$#" -ne 0 ]; then
      loge "Usage: $0 [--locked|--regen-locks]"
      exit 100
   fi

elif [ "$1" = "--locked" ]; then
   regen_locks=false

   if [ "$#" -ne 1 ]; then
      loge "Usage: $0 [--locked|--regen-locks]"
      exit 100
   fi

elif [ "$#" -ne 0 ]; then
   loge "Usage: $0 [--locked|--regen-locks]"
   exit 100
fi

cd "$(dirname "$0")/.." || exit 101

# --- --- ---

setup_switch() {
   switch_name="$1" && shift
   formula="$1" && shift
   package_file="$1" && shift

   full_switch="${SWITCH_PREFIX}-${switch_name}"

   if opam switch list --short | grep -qx "$full_switch"; then
      logs "Resetting existing '$full_switch'..."
      # shellcheck disable=SC2046
      opam remove --switch="$full_switch" --auto-remove $(
         opam list --switch="$full_switch" --roots --short \
         | grep -v 'ocaml-base-compiler\|ocaml-options\|ocaml-config\|base-'
      )
   else
      logs "Creating '$full_switch' with invariant '$formula'..."
      opam switch create "$full_switch" --formula="$formula" \
         "$@" --deps-only --no-install
   fi

   logs "Installing dependencies for '$package_file'..."
   opam install --switch="$full_switch" "./$package_file" \
      "$@" --deps-only --with-doc --with-test --with-dev-setup

   if [ "$regen_locks" = true ]; then
      logs "Regenerating lockfile for '$package_file'..."
      opam lock --switch="$full_switch" "./$package_file"
   fi
}

setup_switch "ocaml-4"     "$OCAML_4_FORMULA" "ambient-context.opam"     "$@"
setup_switch "lwt-ocaml-4" "$OCAML_4_FORMULA" "ambient-context-lwt.opam" "$@"
setup_switch "eio-ocaml-5" "$OCAML_5_FORMULA" "ambient-context-eio.opam" "$@"

if ! [ -d "_opam" ]; then
   opam switch link "${SWITCH_PREFIX}-ocaml-4" .
fi

logs "All done; now run this to sync your shell environment:"
logs ''
# shellcheck disable=SC2016
logs '    eval $(opam env --set-switch --switch='"$SWITCH_PREFIX"'-ocaml-4)'
