#!/bin/bash
#####################################################################################
# Script: ldap-dump.sh  |  By: John Harper
#####################################################################################
# ldap-dump.sh is useful to dump LDAP users.
# - Modify the end of ldapsearch_command to change which attributes are returned 
# - Requires you have valid LDAP user creds
# - Don't have valid creds? Try kspray.sh.
# - Does not support Secure LDAP on TCP Port 636
#####################################################################################

output_file_attributes="ldap_users_attributes.txt"
output_file_users="ldap_users.txt"

# Color codes
YELLOW="\e[33m"
DARKGREEN="\e[32m"
GREEN="\e[32;1m"
BLUE="\e[94m"
RED="\e[91m"
NC="\e[0m"  # No color

# Function to check if a port is open
is_port_open() {
  if nc -z -w 2 $1 $2; then
    echo -e "${DARKGREEN}LDAP port is open on $1:$2${NC}"
    echo -e "\n"
    return 0
  else
    echo -e "${RED}LDAP port is closed on $1:$2${NC}"
    return 1
  fi
}

title () {
    echo -e "${GREEN} "
    echo ICBfICAgICBfX19fICAgIF8gICAgX19fXyAgICAgICBfX19fICAgICAgICAgICAgICAgICAgICAgICAgCiB8IHwgICB8ICBfIFwgIC8gXCAgfCAgXyBcICAgICB8ICBfIFwgXyAgIF8gXyBfXyBfX18gIF8gX18gIAogfCB8ICAgfCB8IHwgfC8gXyBcIHwgfF8pIHxfX19ffCB8IHwgfCB8IHwgfCAnXyBgIF8gXHwgJ18gXCAKIHwgfF9fX3wgfF98IC8gX19fIFx8ICBfXy9fX19fX3wgfF98IHwgfF98IHwgfCB8IHwgfCB8IHxfKSB8CiB8X19fX198X19fXy9fLyAgIFxfXF98ICAgICAgICB8X19fXy8gXF9fLF98X3wgfF98IHxffCAuX18vIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHxffCAgICAKCg== |base64 -d
    echo -e "${YELLOW}=================================================================="
    echo -e "${YELLOW} ldap-dump.sh | [Version]: 1.0.0 | [Updated]: 10.27.2023"
    echo -e "${YELLOW}=================================================================="
    echo -e "${YELLOW} [By]: John Harper | [GitHub]: https://github.com/rollinz007"
    echo -e "${YELLOW}==================================================================${NC}"
    echo -e "${DARKGREEN}Dumping LDAP since 1993!${NC}"
    echo
}

title

# Check if ldapsearch is installed
if ! command -v ldapsearch &>/dev/null; then
  echo -e "${RED}ldapsearch is not installed. Please install it to use this script.${NC}"
  exit 1
fi

# Check if nc (netcat) is installed
if ! command -v nc &>/dev/null; then
  echo -e "${RED}nc (netcat) is not installed. Please install it to use this script.${NC}"
  exit 1
fi

# Prompt the user for input
read -p "Enter username (UPN format e.g., user@domain.local): " username
read -s -p "Enter user password: " password
echo  # Print a newline after password input for better formatting
read -p "Enter the LDAP server (e.g., server.example.com or IP address): " ldap_server_input
read -p "Enter the LDAP port (default is 389): " ldap_port
ldap_port=${ldap_port:-389}

# Check if the LDAP port is open
if ! is_port_open $ldap_server_input $ldap_port; then
  echo -e "${RED}Please check the LDAP server and port settings.${NC}"
  exit 1
fi

# Extract the domain part from the username
domain=$(echo $username | awk -F@ '{print $2}')

# Construct the DC version of the domain
IFS='.' read -ra domain_parts <<< "$domain"
dc_domain=""
for part in "${domain_parts[@]}"; do
  dc_domain+="dc=$part,"
done
dc_domain=${dc_domain%,}  # Remove the trailing comma

# Run LDAP query
ldapsearch_command="ldapsearch -x -LLL -E pr=1000/noprompt -D \"$username\" -w \"$password\" -H \"ldap://$ldap_server_input:$ldap_port\" -b \"$dc_domain\" \"(objectClass=user)\" dn cn pwdLastSet primaryGroupID accountExpires logonCount userPrincipalName > $output_file_attributes"
eval $ldapsearch_command
if [ -s "$output_file_attributes" ]; then
  grep "userPrincipalName" $output_file_attributes |cut -d'@' -f1 |cut -d' ' -f2 |sort -f > $output_file_users
  usercount=$(cat "$output_file_users" | wc -l)
  echo -e "${GREEN}Users with attributes exported to: ${BLUE}$output_file_attributes${NC}"
  echo -e "${GREEN}Users exported to: ${BLUE}$output_file_users${NC}"
  echo -e "${YELLOW}$usercount ${GREEN}accounts exported${NC}"
else
  rm "$output_file_attributes"
  echo -e "${RED}An error occurred.${NC}"
fi
