#!/bin/sh
set -o pipefail

SNAPSERVER_API_PORT="1780"

# Check Supervisord status
supervisorctl -c /app/supervisord/supervisord.conf status || exit 1
echo "All supervisord-managed processes are healty."

# Test snapserver and retrieve snapserver status
API_RESPONSE=$(curl --silent --user-agent healthcheck -X POST -d '{"id":1,"jsonrpc":"2.0","method":"Server.GetStatus"}' http://localhost:${SNAPSERVER_API_PORT}/jsonrpc)
if [ ! "$?" -eq 0 ]; then
    echo "Snapserver API not reachable."
    exit 2
fi

# Check snapserver API response
echo "${API_RESPONSE}" | grep -q "snapserver" || exit 3
echo "Snapserver API is healty."

exit 0
