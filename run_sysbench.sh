pgip=$1
port=5433
user=yugabyte
db=yugabyte
run_threads=64
table_size=100000
num_tables=10
time=60

sqlsh=/repositories/yugabyte-db/bin/ysqlsh

delete_tables() {
  for i in `seq $num_tables`; do $sqlsh -h $pgip -c "drop table sbtest$i;"; done
}

run_workload() {
  echo "RUNNING $1"
  time sysbench oltp_insert --tables=$num_tables --table-size=$table_size --range_key_partitioning=true --serial_cache_size=1000 --db-driver=pgsql --pgsql-host=$pgip --pgsql-port=$port --pgsql-user=$user --pgsql-db=$db --threads=1 prepare
  time sysbench $1 --tables=$num_tables --table-size=$table_size --range_key_partitioning=true --serial_cache_size=1000 --db-driver=pgsql --pgsql-host=$pgip --pgsql-port=$port --pgsql-user=$user --pgsql-db=$db --threads=$run_threads --time=$time --warmup-time=120 run
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
