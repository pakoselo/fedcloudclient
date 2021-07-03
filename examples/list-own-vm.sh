#!/usr/bin/env bash

# This script will print a list VMs owned by the user in the given VO/site
# Required fedcloudclient
# OIDC token for authentication should be set via environment variable
# either via OIDC_ACCESS_TOKEN or OIDC_AGENT_ACCOUNT
# See https://fedcloudclient.fedcloud.eu/quickstart.html for more information

# Usage: list-own-vm.sh --site <SITE> --vo <VO>

# Usage info
show_help() {
cat << EOF
Usage: ${0##*/} [-h] --site  <SITE> --vo <VO>
List all VMs owned by the user in the given VO/site
Arguments:
	-h, --help, help		Display this help message and exit
	--site SITE :	Site name
	--vo VO : VO name
EOF
}

# Default values for SITE and VO
SITE=UNKNOWN
VO=UNKNOWN

# List of columns to be displayed
# Other possible columns like "Status", "Flavor Name", "Image Name"
COLUMNS="-c ID -c Name -c Networks"

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    --site)
    SITE="$2"
    shift # past argument
    shift # past value
    ;;
    --vo)
    VO="$2"
    shift # past argument
    shift # past value
    ;;
    -h|--help|help)
    show_help
    exit 0
    shift # past argument
    ;;
    *)
    echo "Invalid argument: $key"
    exit 1
    ;;
esac
done

if [ -z "$OIDC_ACCESS_TOKEN" ] && [ -z "$OIDC_AGENT_ACCOUNT" ]; then
    echo "Access token via OIDC_ACCESS_TOKEN or OIDC_AGENT_ACCOUNT is required"
    exit 1
fi

if [[ $SITE == "UNKNOWN" || $VO == "UNKNOWN" ]]; then
    echo "Error: Site and VO name are required."
    show_help
    exit 1
fi

if [ "$SITE" == "ALL_SITES" ]; then
    echo "Error: Due to different local user IDs at different sites, ALL_SITES operation is not supported."
    exit 1
fi


# List all VMs in the VO on the site in JSON format
# shellcheck disable=SC2086
LIST_ALL_VM=$(fedcloud openstack server list --site $SITE --vo $VO $COLUMNS -c "User ID" --json-output)

# Get local User ID on the site
USER_ID=$(fedcloud openstack token issue -c user_id -f value --site "$SITE" --vo "$VO" 2> /dev/null)

# Select only VMs with the User ID
# shellcheck disable=SC2086
echo $LIST_ALL_VM | jq -r  '.[].Result | map(select(."User ID" == "'$USER_ID'")) | .'
