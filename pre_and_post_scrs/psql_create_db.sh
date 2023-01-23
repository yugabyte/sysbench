#!/usr/bin/bash
echo -e "\n ======= `date`:: CREATE DATABASE script called ...... ======== \n" > /tmp/psql_create_db.log
export pgsqlpath=$1
export ybsrv=$2
export pgpass=$3
export dbname=$4
export coloflag=$5
if [[ ${coloflag} == "true" ]]; then
  echo -e "\n ==== Selected colo ==== \n"
  export setcolo="colocated=true"
fi
echo -e "PGPASSWORD=${pgpass} ${pgsqlpath} -h ${ybsrv} -p 5433 -U yugabyte -c \"CREATE DATABASE ${dbname} ${setcolo};\" " >> /tmp/psql_create_db.log
PGPASSWORD=${pgpass} ${pgsqlpath} -h ${ybsrv} -p 5433 -U yugabyte -c "CREATE DATABASE ${dbname} ${setcolo};" >> /tmp/psql_create_db.log & 2>&1
sleep 5
PGPASSWORD=${pgpass} ${pgsqlpath} -h ${ybsrv} -p 5433 -U yugabyte -c "\l+" >> /tmp/psql_create_db.log & 2>&1
echo -e "\n ============== CREATE DATABASE  done at: `date` ===================  \n" >> /tmp/psql_create_db.log
/usr/bin/cat /tmp/psql_create_db.log
