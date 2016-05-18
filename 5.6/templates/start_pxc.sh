#!/bin/bash

cd $(dirname $0)

## Sometimes you need to...
random_sleep()
{
    SLEEP_TIME=$RANDOM
    let "SLEEP_TIME %= 15"
    sleep ${SLEEP_TIME}
}

./giddyup service wait scale

PXC_CONF='/etc/mysql/conf.d/001-pxc.cnf'

# Start confd in background
/opt/rancher/confd --interval 10 --backend rancher --prefix "/2015-07-25" &

echo "Waiting for Config..."
while [ ! -f "${PXC_CONF}" ]; do
   sleep 5
done
echo "Starting pxc..."

if [ "$#" -eq "0" ]; then
    leader="false"

    ./giddyup leader check
    if [ "$?" -eq "0" ]; then
        leader="true"
    fi

    set -- mysqld --wsrep_cluster_address=gcomm://$(./giddyup ip stringify)?pc.wait_prim=no
    if [ "${leader}" = "true" ]; then
        set -- mysqld --wsrep-new-cluster --wsrep_cluster_address=gcomm://$(./giddyup ip stringify)?pc.wait_prim=no
    fi
    touch /opt/rancher/configured
    if [ "${leader}" = "true" ] && [ ! -f "/opt/rancher/initialized" ]; then
        set -- mysqld --wsrep-new-cluster --wsrep_cluster_address=gcomm://$(./giddyup ip stringify)?pc.wait_prim=no
        rm -rf /opt/rancher/configured
        touch /opt/rancher/initialized
    fi

    ## Incase this is the initial startup.
    if [ "${leader}" = "false" ]; then
        random_sleep
    fi
fi

exec /docker-entrypoint.sh "$@"
