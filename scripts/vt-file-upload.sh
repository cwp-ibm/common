source vt-api-key.env

FULL_FILE_PATH=$1

VT_UPLOAD_RESPONSE=$(curl --request POST \
  --url https://www.virustotal.com/api/v3/files \
  --header "x-apikey: ${VT_API_KEY}" \
  --form file=@${FULL_FILE_PATH})

VT_HASH_ID=$(echo $VT_UPLOAD_RESPONSE | jq .data.id )

echo $VT_HASH_ID > VT_Hasd_ID.txt


