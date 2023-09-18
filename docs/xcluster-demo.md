# Demo xCluster

## Requirements

1. YBA 2.18 and above
2. 2 DB Clusters
3. Backup store is setup
4. Machine with YugabyteDB is installed
5. Source and Target universes must be accessible (YSQL and Master-RPC)


## Architecture Diagram

## Cluster creation information

- 2 Clusters (Active and Standby)
- Clusters created with following gflags
  - Tserver:
    - `consensus_max_batch_size_bytes` =`1048576`
    - `rpc_throttle_threshold_bytes` =`524288`
    - `ysql_num_shards_per_tserver` =`3`
    - `log_min_seconds_to_retain` =`86400`

    ```json
    {
      "consensus_max_batch_size_bytes": "1048576",
      "rpc_throttle_threshold_bytes": "524288",
      "ysql_num_shards_per_tserver": "3",
      "log_min_seconds_to_retain": "86400"
    }
    ```
  - Master:
    - `enable_automatic_tablet_splitting` = `false`
    - `enable_tablet_split_of_xcluster_replicated_tables` = `false`

    ```json
    {
      "enable_automatic_tablet_splitting": "false",
      "enable_tablet_split_of_xcluster_replicated_tables": "false"
    }
    ```

## Prepare

1. Get CA SSL Cert for Source and Target and save it at `/tmp/source.ca.pem` and `/tmp/target.ca.pem`
   You can easily get it from the **Universe Overview > Action Menu > Run Sample Apps > YCQL**. Copy everything between (and including) `-----BEGIN CERTIFICATE-----` and `-----END CERTIFICATE-----`. Do this for each universe and store the files correctly.

1. Setup env variables

    ```bash
    export PGDATABASE=testdb
    export PGPASSWORD=Password#123
    export ACTIVE_NODE=10.98.61.210
    export ACTIVE_MASTER=10.98.61.210
    export ACTIVE_MASTERS=$ACTIVE_MASTER:7100,10.98.59.199:7100,10.98.57.6:7100
    export ACTIVE_SSH_KEY=$HOME/.yugabyte/yb-apj-demo-shr-ybdb.pem
    export STANDBY_NODE=10.98.45.119
    export STANDBY_MASTER=10.98.45.119
    export STANDBY_MASTERS=$STANDBY_MASTER:7100,10.98.41.64:7100,10.98.43.210:7100
    export STANDBY_SSH_KEY=$HOME/.yugabyte/yb-apj-demo-shr-ybdb.pem

    export PGSSLMODE=require
    export ACTIVE_CA_CERT==/tmp/source.ca.pem
    export STANDBY_CA_CERT==/tmp/target.ca.pem
    export YUGABYTEDB_HOME=$HOME/Workspace/Yugabyte/yugabyte
    ```
1. Create database `testdb` with `northwind` schema on both sides

    Source / Active Side:

    ```bash
    $YUGABYTEDB_HOME/bin/ysqlsh "sslrootcert=$ACTIVE_CA_CERT" -h $ACTIVE_NODE -c "CREATE DATABASE $PGDATABASE"
    $YUGABYTEDB_HOME/bin/ysqlsh "sslrootcert=$ACTIVE_CA_CERT" -h $ACTIVE_NODE -f $YUGABYTEDB_HOME/share/northwind_ddl.sql
    ```

1. Setup replication

   Follow [docs](https://docs.yugabyte.com/stable/yugabyte-platform/create-deployments/async-replication-platform/)


1. Add data

    ```bash
    $YUGABYTEDB_HOME/bin/ysqlsh "sslrootcert=$ACTIVE_CA_CERT" -h $ACTIVE_NODE -f $YUGABYTEDB_HOME/share/northwind_data.sql
    ```

    (Optional) Check data

    ```bash
    $YUGABYTEDB_HOME/bin/ysqlsh "sslrootcert=$ACTIVE_CA_CERT" -h $ACTIVE_NODE -c 'select count(*) from categories'
    ```

1. Verify the replication
    ```bash
    $YUGABYTEDB_HOME/bin/ysqlsh "sslrootcert=$STANDBY_CA_CERT" -h $STANDBY_NODE -c 'select count(*) from categories'
    ```

1. Check that Standby is not writable

    ```bash
    $YUGABYTEDB_HOME/bin/ysqlsh "sslrootcert=$STANDBY_CA_CERT" -h $STANDBY_NODE -c "insert into categories values (101,  'FAIL', 'THis must fail', '\x');"
    ```

## Unplanned Failover

1. Go to standby master node via SSH

    ```bash
    ssh -i $STANDBY_SSH_KEY  -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" yugabyte@$STANDBY_MASTER
    ```

2. Get safe time

    ```bash
    master/bin/yb-admin \
      -init_master_addrs $HOSTNAME:7100 \
      -certs_dir_name /home/yugabyte/yugabyte-tls-config \
      get_xcluster_safe_time include_lag_and_skew
    ```
3. Using YBA, restore to PITR at data and time suggested in previouse command output

4. Promote standby to ACTIVE

    ```bash
    master/bin/yb-admin \
      -init_master_addrs $HOSTNAME:7100 \
      -certs_dir_name /home/yugabyte/yugabyte-tls-config \
      change_xcluster_role ACTIVE

    ```

5. Delete the replication setup from YBA

### Failback to old ACTIVE

1. Disable PITR on original ACTIVE


## Automated
1. Get [xcluster-ctl](https://github.com/hari90/xcluster-ctl)

    ```bash
    git clone git@github.com:hari90/xcluster-ctl.git xcluster-ctl
    ```

2. Record configuration of xcluster work

    ```bash
    # Configure cluster and yba details
    > python3 xcluster-ctl/xcluster-ctl.py configure
    ```
    Sample Output:

    ```log
    $ python3 xcluster-ctl.py  configure
    Are these universe managed by YBA? (yes/no): yes
    Enter the YBA url: https://yba-internal.demo.aws.apj.yugabyte.com
    Get the Customer ID and API Token from https://yba-internal.demo.aws.apj.yugabyte.com/profile
    Enter the customer id: dc2b055a-2278-4fc0-a876-85fe7dcfb785
    Enter the auth token: 506ea95b-3207-4742-a815-4270dff37f0a

    Enter one Source universe master IP: 10.98.59.199
    Enter Source universe ssh port (default is 54422): 22
    Enter Source universe ssh cert file location: /opt/yugabyte/yugaware/data/keys/921db0e3-ac17-431b-91f6-6f477645cd02/yb-dev-aws-shared_921db0e3-ac17-431b-91f6-6f477645cd02-key.pem
    Getting master list
    Getting ca.crt
    Getting universe info
    Getting tserver list

    Enter one Target universe master IP: 10.98.41.64

    ssh port:		22
    ssh cert file path:	/opt/yugabyte/yugaware/data/keys/921db0e3-ac17-431b-91f6-6f477645cd02/yb-dev-aws-shared_921db0e3-ac17-431b-91f6-6f477645cd02-key.pem
    Do you want to use these settings for the Target universe as well? (yes/no): yes
    Getting master list
    Getting ca.crt
    Getting universe info
    Getting tserver list
    Copying cert files to yb-dev-xcluster-demo-target
    Copying cert files to yb-dev-xcluster-demo-source
    Successfully synced YBA
    YBA Config:
    {'url': 'https://yba-internal.demo.aws.apj.yugabyte.com', 'customer_id': 'dc2b055a-2278-4fc0-a876-85fe7dcfb785', 'token': '506ea95b-3207-4742-a815-4270dff37f0a'}
    Source Universe:
    {'universe_name': 'yb-dev-xcluster-demo-source', 'master_ips': '['10.98.57.6', '10.98.59.199', '10.98.61.210']', 'tserver_ips': '['10.98.61.210', '10.98.59.199', '10.98.57.6']', 'role': 'ACTIVE'}
    Target Universe:
    {'universe_name': 'yb-dev-xcluster-demo-target', 'master_ips': '['10.98.41.64', '10.98.43.210', '10.98.45.119']', 'tserver_ips': '['10.98.45.119', '10.98.41.64', '10.98.43.210']', 'role': 'ACTIVE'}
    Successfully configured

    Validating flags on yb-dev-xcluster-demo-source
    Validating flags on yb-dev-xcluster-demo-target
    Universe validation successful
    ```
3. Reload current roles

    ```bash
    # Load current roles of the clusters
    > python3 xcluster-ctl/xcluster-ctl.py reload_roles
    ```

    Sample Output:

    ```log
    [ dba-async-1 -> dba-async-2 ]
    Portal Config:
    {'url': 'https://52.55.102.221', 'customer_id': 'b452ec1a-c4bf-4e3e-86ff-0d046e4b9c91', 'token': 'eb43036c-f64e-4971-86f6-257fdb96869a'}
    Primary Universe:
    {'universe_name': 'dba-async-1', 'master_ips': '['10.37.1.235', '10.37.2.253', '10.37.3.54']', 'tserver_ips': '['10.37.2.253', '10.37.1.235', '10.37.3.54']', 'role': 'ACTIVE'}
    Standby Universe:
    {'universe_name': 'dba-async-2', 'master_ips': '['10.37.3.161', '10.37.3.43', '10.37.3.91']', 'tserver_ips': '['10.37.3.91', '10.37.3.161', '10.37.3.43']', 'role': 'STANDBY'}
    ```

4. Switch Universe Configs

    ```bash
    > python3 xcluster-ctl/xcluster-ctl.py switch_universe_configs
    ```

    Sample Output:
    ```bash
    [ dba-async-2 -> dba-async-1 ]
    Swapping Primary and Standby universes
    [ dba-async-1 -> dba-async-2 ]
    ```

5. Initiate a planned failover

    ```bash
    > python3 xcluster-ctl/xcluster-ctl.py planned_failover
    ```

    Sample Output:

    ```log
    [ dba-async-1 -> dba-async-2 ]
    Performing a planned failover from dba-async-1 to dba-async-2
    Found replication group 1-to-3 with 178 tables
    Has the workload been stopped? (yes/no): yes << stop the application workflow on Primary
    Waiting for drain of 178 replication streams...
    .
    All replications are caught-up.
    Successfully completed wait for replication drain
    database_name:		test1
    xcluster_safe_time:	2023-06-27 23:03:13.651436
    database_name:		yugabyte
    xcluster_safe_time:	2023-06-27 23:03:13.795260
    Setting dba-async-2 to ACTIVE
    Successfully set role to ACTIVE
    Deleting replication 1-to-3 from dba-async-1 to dba-async-2
    Replication deleted successfully
    Setting dba-async-2 to ACTIVE
    Already in ACTIVE role
    Successfully synced Portal
    Successfully deleted replication
    Swapping Primary and Standby universes
    [ dba-async-2 -> dba-async-1 ]
    Setting up replication from dba-async-2 to dba-async-1 with bootstrap
    Setting up PITR snapshot schedule for yugabyte on dba-async-2
    Successfully created PITR snapshot schedule for yugabyte
    Getting tables for database(s) test3,test8,test6,test5,yugabyte,test2,test10,test7,test9,test1,test4 from dba-async-2
    .
    Checkpointing 178 tables
    .
    Successfully bootstrapped databases. Run setup_replication_with_bootstrap command to complete setup
    Copying cert files to dba-async-1
    Replication setup successfully
    Setting up PITR snapshot schedule for yugabyte on dba-async-1
    Successfully created PITR snapshot schedule for yugabyte
    Setting dba-async-1 role to STANDBY
    Successfully synced Portal
    database_name:		test1
    xcluster_safe_time:	2023-06-27 23:04:05.358696
    database_name:		yugabyte
    xcluster_safe_time:	2023-06-27 23:04:05.450287
    Successfully setup replication
    Successfully failed over from dba-async-1 to dba-async-2
    ```

