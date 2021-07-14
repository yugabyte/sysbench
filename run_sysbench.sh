#!/bin/bash

# Get the IP, numtables and the tablesize from the user. The default value for the
# numtables is 10, tablesize is 100k and for the ip is '127.0.0.1'.
#
# Run the script as './run_sysbench.sh --ip 192.168.1.2 --numtables 10 --tablesize 1000'
tablesize=${tablesize:-100000}
numtables=${numtables:-10}
ip=${ip:-127.0.0.1}
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
run_threads=64
time=120
warmuptime=120

delete_tables() {
  # Make sure that ysqlsh is present in the 'PATH'.
  for i in `seq $numtables`; do ysqlsh -h $ip -c "drop table sbtest$i;"; done
}

run_workload() {
  echo "RUNNING $1"
  echo Writing output to $1-load.dat and $1-run.dat
  time sysbench $1 --tables=$numtables --table-size=$tablesize --range_key_partitioning=true --serial_cache_size=1000 --db-driver=pgsql --pgsql-host=$ip --pgsql-port=$port --pgsql-user=$user --pgsql-db=$db prepare > $1-load.dat
  time sysbench $1 --tables=$numtables --table-size=$tablesize --range_key_partitioning=true --serial_cache_size=1000 --db-driver=pgsql --pgsql-host=$ip --pgsql-port=$port --pgsql-user=$user --pgsql-db=$db --threads=$run_threads --time=$time --warmup-time=120 run > $1-run.dat
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
