#!/bin/bash
# Obtain the token from the environment
vultr_api_token=$(cat $HOME/.tokens/vultr_api.token)
# Apply the command
terraform destroy -var="vultr_api_token=$vultr_api_token" -var="private_key=none"
