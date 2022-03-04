#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
. /opt/ivy/bash_functions.sh

THIS_SCRIPT=$(basename "${0}")

function usage () {
  echo "Usage:"
  echo "${THIS_SCRIPT} -c,--coredns-resolver <CoreDNS' ClusterIP>"
  echo
  echo "Configure dnsmasq to use DNS server specified in DHCP options"
  echo "If --coredns-resolver is specified, it will configure dnsmasq"
  echo "to use coredns for *.$(get_ivy_tag)"
  exit
}

COREDNS='none'
while [[ $# -gt 0 ]]; do
  case "${1}" in
      -c|--coredns-resolver)
        COREDNS="${2}"
        shift # past argument
        shift # past value
        ;;
      -*)
        echo "Unknown option ${1}"
        usage
        ;;
  esac
done

function update_dnsmasq_conf() {
  local OLD_STRING="${1}"
  local NEW_STRING="${2}"
  local QUERY="${OLD_STRING}/${NEW_STRING}"
  sed -i "${QUERY}" /etc/dnsmasq.d/10-dnsmasq
}

DNS="$(grep 'domain-name-servers' "/var/lib/dhclient/dhclient--$(get_primary_interface).leases" | head -1)"

update_dnsmasq_conf '%%DHCP_DNS%%' "${DNS}"

if [[ "${COREDNS}" != 'none' ]]; then
  update_dnsmasq_conf '^#server=' 'server='
  update_dnsmasq_conf '%%TAG_NAMESPACE%%' "$(get_ivy_tag)"
  update_dnsmasq_conf '%%COREDNS%%' "${COREDNS}"
fi
