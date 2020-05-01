#!/bin/bash

# Get the IP, numtables and the tablesize from the user. The default value for the
# numtables is 10, tablesize is 100k and for the ip is '127.0.0.1'.
ip=${ip:-127.0.0.1}
tablesize=${tablesize:-100000}
numtables=${numtables:-10}
while [ $# -gt 0 ]; do
   if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare $param="$2"
   fi
  shift
done

port=5433
user=yugabyte
db=yugabyte
runthreads=64
time=120
warmuptime=120

delete_tables() {
  for i in `seq $numtables`; do ysqlsh -h $ip -c "drop table sbtest$i;"; done
}

run_workload() {
  echo "RUNNING $1"
  time sysbench $1 --tables=$numtables --table-size=$tablesize --range_key_partitioning=true --serial_cache_size=1000 --db-driver=pgsql --pgsql-host=$ip --pgsql-port=$port --pgsql-user=$user --pgsql-db=$db --threads=1 prepare
  time sysbench $1 --tables=$numtables --table-size=$tablesize --range_key_partitioning=true --serial_cache_size=1000 --db-driver=pgsql --pgsql-host=$ip --pgsql-port=$port --pgsql-user=$user --pgsql-db=$db --threads=$runthreads --time=$time --warmup-time=$warmuptime run
  delete_tables
  echo "DONE $1"
}

run_workload oltp_insert
run_workload oltp_point_select
run_workload oltp_write_only
run_workload oltp_read_only
run_workload oltp_read_write
run_workload oltp_update_index
run_workload oltp_update_non_index
run_workload oltp_delete
