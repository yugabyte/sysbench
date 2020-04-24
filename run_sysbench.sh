pgip=127.0.0.1
port=5433
user=yugabyte
db=yugabyte
run_threads=64
table_size=1000000
time=120
prefx='YB_1Mil_'

load_workload() {
  echo "LOADING"
  time sysbench oltp_insert --tables=1 --table-size=$table_size --range_key_partitioning=true --serial_cache_size=1000 --db-driver=pgsql --pgsql-host=$pgip --pgsql-port=$port --pgsql-user=$user --pgsql-db=$db --threads=1 prepare > $prefx_load.txt
  echo "DONE LOADING"
}

run_workload() {
  echo "RUNNING $1"
  time sysbench $1 --tables=1 --table-size=$table_size --range_key_partitioning=true --serial_cache_size=1000 --db-driver=pgsql --pgsql-host=$pgip --pgsql-port=$port --pgsql-user=$user --pgsql-db=$db --threads=$run_threads --time=$time --warmup-time=120 run > $prefx$1.txt
  echo "DONE $1"
}

load_workload
run_workload oltp_insert
run_workload oltp_point_select
run_workload oltp_write_only
run_workload oltp_read_only
run_workload oltp_read_write
run_workload oltp_update_index
run_workload oltp_update_non_index
run_workload oltp_delete
