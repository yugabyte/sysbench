#!/usr/bin/bash
echo -e " ======= In script ...... ======== "
echo "PGPASSWORD=${2} /usr/bin/psql -h ${1} -p 5433 -U yugabyte -c \"SELECT pg_sleep(1), 'Pre-LOAD Sleep done...' as msg;\" &"
PGPASSWORD=${2} /usr/bin/psql -h ${1} -p 5433 -U yugabyte -c "SELECT pg_sleep(1), 'Pre-LOAD Sleep done...' as msg;" &
