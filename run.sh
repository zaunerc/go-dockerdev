#!/bin/bash
set -e
. common.sh
CID=$(docker run --detach -P "$IMAGE_NAME")
SSH_PORT=$(docker inspect --format='{{(index (index .NetworkSettings.Ports "22/tcp") 0).HostPort}}' $CID)
CNTRINFOD_PORT=$(docker inspect --format='{{(index (index .NetworkSettings.Ports "2020/tcp") 0).HostPort}}' $CID)
NAME=$(docker inspect --format='{{.Name}}' $CID | sed 's/\/\(.*\)/\1/')

USER="gopher"

PASSWORD=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c12)
docker exec $CID sh -c "echo $PASSWORD | sed 's/\(.*\)/$USER:\1/' | chpasswd"

cat << EOF

-----------------------------------------------------------

go-dockerdev container is now running with
name $NAME. Next steps:

1. Login using ssh using '$USER' as username
   and '$PASSWORD' as password:

   $ ssh -p $SSH_PORT $USER@localhost

2. Git has been configured using the following
   commands:

   $ git config --global user.name "Christoph Zauner"
   $ git config --global user.email "christoph.zauner@NLLK.net"

   Rerun if necessary.

3. Open the cntrinfod web site of the container
   for further informations:

   http://localhost:$CNTRINFOD_PORT

-----------------------------------------------------------

EOF

