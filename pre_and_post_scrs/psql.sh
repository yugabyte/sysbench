#!/usr/bin/bash
echo -e " ======= `date`:: Pre-load script called ...... ======== " > /tmp/psql_sh.log
for ybsrv in `echo ${1} | tr "," " "`;
do
   echo "PGPASSWORD=${2} /usr/bin/psql -h ${ybsrv} -p 5433 -U yugabyte -c \"SELECT pg_sleep(${3}), 'Pre-LOAD Sleep done...' as msg;\" &" >> /tmp/psql_sh.log
   PGPASSWORD=${2} /usr/bin/psql -h ${ybsrv} -p 5433 -U yugabyte -c "SELECT pg_sleep(${3}), 'Pre-LOAD Sleep done...' as msg;" >> /tmp/psql_sh.log & 2>&1
done
