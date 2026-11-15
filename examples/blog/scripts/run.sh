#!/usr/bin/env bash
#
# Serve the blog API against a throwaway MySQL in Docker.
#
#   scripts/run.sh                       # mysql:8.0, the API on 127.0.0.1:8089
#   IMAGE=mariadb:11 HTTP_PORT=9000 scripts/run.sh
#
# Against a server of your own, skip this and run the exe directly:
#
#   cd app && echoc build && ecobuild/blog --url mysql://user:pass@host:3306/db

set -euo pipefail

IMAGE=${IMAGE:-mysql:8.0}
NAME=rest-blog-$$
HTTP_PORT=${HTTP_PORT:-8089}
PORT=${PORT:-$(python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])')}

cd "$(dirname "$0")/../app"

echoc build

docker run -d --rm --name "$NAME" \
    -e MYSQL_ROOT_PASSWORD=rootpw -e MYSQL_DATABASE=blog -e MYSQL_USER=app -e MYSQL_PASSWORD=secret \
    -e MARIADB_ROOT_PASSWORD=rootpw -e MARIADB_DATABASE=blog -e MARIADB_USER=app -e MARIADB_PASSWORD=secret \
    -p "127.0.0.1:$PORT:3306" "$IMAGE" >/dev/null
trap 'docker rm -f -v "$NAME" >/dev/null 2>&1 || true' EXIT

echo "waiting for $IMAGE on 127.0.0.1:$PORT"
for _ in $(seq 1 120); do
    if docker exec "$NAME" sh -c 'command -v mysql' >/dev/null 2>&1; then CLIENT=mysql; else CLIENT=mariadb; fi
    if docker exec "$NAME" "$CLIENT" -uroot -prootpw -h127.0.0.1 -e 'SELECT 1' >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

# a fresh server's first login takes the RSA path, which needs the server key over plain TCP
ecobuild/blog --url "mysql://app:secret@127.0.0.1:$PORT/blog?fetchServerKey=true" --port "$HTTP_PORT"
