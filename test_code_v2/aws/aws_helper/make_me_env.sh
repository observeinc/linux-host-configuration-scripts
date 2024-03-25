#!/usr/bin/env bash

SPACER="########################################"
END_OUTPUT="END_OF_OUTPUT"

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

budget_amount=100.0
budget_currency=USD
expiry=7d
aws_creds_path="./aws-creds"

log ()
{
    echo "$1" 
}

printHelp(){
      log "$SPACER"
      log "## HELP CONTENT"
      log "$SPACER"
      log "### Required inputs"
      log "- Required --principal_id whatever feel free to use your email address"
      log "- Required --email your email address"
      log "## Optional inputs"
      log "- Optional --budget_amount - Defaults to 100 "
      log "- Optional --budget_currency - Defaults to USD"
      log "- Optional --expiry - Defaults to 7d"
      log "- Optional --aws_cred_path - Defaults to /Users/arthur/observe/s/aws-creds"
      log "***************************"
      log "### Sample command:"
      log "\`\`\` ./make_me_env.sh --principal_id $USER@observeinc.com --email $USER@observeinc.com \`\`\`"
      log "***************************"
}

if [ "$1" == "--help" ]; then
  printHelp
  log "$SPACER"
  log "$END_OUTPUT"
  log "$SPACER"
  exit 0
fi

requiredInputs(){
      log "$SPACER"
      log "* Error: Invalid argument.*"
      log "$SPACER"
      printVariables
      printHelp
      log "$SPACER"
      log "$END_OUTPUT"
      log "$SPACER"
      exit 1

}

printVariables(){
      log "$SPACER"
      log "* VARIABLES *"
      log "$SPACER"
      log "principal_id: $principal_id"
      log "email: $email"
      log "aws_creds_path: $aws_creds_path"
      log "$SPACER"
}

if [ $# -lt 2 ]; then
  requiredInputs
fi

    # Parse inputs
    while [ $# -gt 0 ]; do
    echo "required inputs $1 $2 $# "
      case "$1" in
        --principal_id)
          principal_id="$2"
          ;;
        --email)
          email="$2"
          ;;
        --budget_amount)
          budget_amount="$2"
          ;;
        --budget_currency)
          budget_currency="$2"
          ;;
        --expiry)
          expiry="$2"
          ;;
        --aws_creds_path)
          aws_creds_path="$2"
          ;;
        *)

      esac
      shift
      shift
    done

PRINCIPAL_ID=$principal_id
BUDGET_AMOUNT=$budget_amount
BUDGET_CURRENCY=$budget_currency
EMAIL=$email
EXPIRY=$expiry
AWS_CREDS_PATH=$aws_creds_path

$AWS_CREDS_PATH checkout blunderdome-user

# /Users/arthur/observe/s/aws-creds checkout blunderdome-user

export AWS_PROFILE=blunderdome-user

lease_id=$(dce leases list --status Active --principal-id $PRINCIPAL_ID | jq -r '.[0].id')
if [[ "$lease_id" == "null" ]]; then
    echo "Creating a new lease..."
    lease_id=$(dce leases create --budget-amount $BUDGET_AMOUNT --budget-currency $BUDGET_CURRENCY --email $EMAIL --principal-id $PRINCIPAL_ID -E $EXPIRY | jq -r '.id')
    if [[ "$lease_id" == "null" ]]; then
    echo "Failed to create a lease. Exiting."
    exit 1
    fi
fi

echo "Logging into lease $lease_id..."
# Execute the credentials script to set the AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_SESSION_TOKEN environment variables
eval $(dce leases login $lease_id -p dce)

echo "To open browser run [ export AWS_PROFILE=blunderdome-user; dce leases login $lease_id  -p dce --open-browser ]"

echo "If you are getting error message try running pybritive logout"

