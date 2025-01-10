ORG="${ORG:-https://dev.azure.com/orgname}"
QUERYFILE="$1"
az boards query --org="$ORG" --wiql=@"$QUERYFILE"
