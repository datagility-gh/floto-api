#!/usr/bin/env bash

cp .devcontainer/.npmrc ~/.npmrc

set -e

read -p 'ADO Artifacts PAT: ' rawToken

base64Token=$(echo -n $rawToken | base64 -w0)

sed -i "s/BASE64_ENCODED_PERSONAL_ACCESS_TOKEN/$base64Token/g" ~/.npmrc
