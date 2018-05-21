#!/usr/bin/env bash

while [ "$1" != "" ]; do
    case $1 in
        -j| --join )           shift
                                join="--join=$1"
                                ;;
#        -i | --interactive )    interactive=1
#				echo $interactive
#                                ;;
#        -h | --help )           usage
#                                exit
#                                ;;
#        * )                     usage
#                                exit 1
    esac
    shift
done


if [ ! -f ./cockroach ]; then
wget https://binaries.cockroachdb.com/cockroach-v2.0.1.linux-amd64.tgz -O cockroach-v2.0.1.linux-amd64.tgz
tar -xf cockroach-v2.0.1.linux-amd64.tgz --strip=1 cockroach-v2.0.1.linux-amd64/cockroach
rm cockroach-v2.0.1.linux-amd64.tgz
fi
if [ ! -d certs ]; then
mkdir certs my-safe-directory
fi
if [ ! -f my-safe-directory/ca.key ]; then
cockroach cert create-ca --certs-dir=certs --ca-key=my-safe-directory/ca.key
fi

PUBLIC_IP=`ifconfig eth0 | grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1`
get_free_port()
{
while true; do
    for port in `seq $1 60999`; do
        if `nc -z $PUBLIC_IP $port`; then
                continue
        else
                echo $port
                break 2
        fi
    done
done
}
HTTP_PORT=$(get_free_port 45000)
SQL_PORT=$(get_free_port 32768)

cockroach cert create-node \
`hostname --all-ip-addresses` \
localhost \
127.0.0.1 \
--certs-dir=certs \
--ca-key=my-safe-directory/ca.key --overwrite

cockroach cert create-client \
root \
--certs-dir=certs \
--ca-key=my-safe-directory/ca.key --overwrite

docker build -t "cockroach:dockerfile" .
export CONTAINER_ID=`docker run -d --rm --net=host --name node$SQL_PORT -h node$SQL_PORT cockroach:dockerfile start --certs-dir=certs -p $SQL_PORT --http-port $HTTP_PORT --host=$PUBLIC_IP $join`
echo $CONTAINER_ID
echo SQL $PUBLIC_IP:$SQL_PORT
echo HTTP $PUBLIC_IP:$HTTP_PORT
