#!/usr/bin/env sh

source .env

ClientId=$API_KEY
ClientSecret=$API_SECRET
Timestamp=$( date +%s000 )
Nonce=$( cat /dev/urandom | tr -dc 'a-z0-9' | head -c8 )
URI="/api/v2/private/get_account_summary?currency=BTC"
HttpMethod=GET
Body=""

Data="${Timestamp}\n${Nonce}\n${HttpMethod}\n${URI}\n${Body}\n"
echo $Data
Signature=$( echo -ne $Data | openssl sha256 -r -hmac "$ClientSecret" | cut -f1 -d' ' )
echo $Signature

curl -s -X ${HttpMethod} -H "Authorization: deri-hmac-sha256 id=${ClientId},ts=${Timestamp},nonce=${Nonce},sig=${Signature}" "https://test.deribit.com${URI}"
