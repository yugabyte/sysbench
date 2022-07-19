#!/usr/bin/env sysbench

-- ----------------------------------------------------------------------
-- Create idle connections - Used to test lot of idle connections
-- $ sysbench sleep --thread-init-timeout=30 --time=30 --warmup-time=0 --db-driver=pgsql
--    --pgsql-db=yugabyte --pgsql-port=5433 --pgsql-user=yugabyte --pgsql-host=127.0.0.1 --threads=10 run
-- ----------------------------------------------------------------------

function thread_init()
    -- create a connection
    drv = sysbench.sql.driver()
    con = drv:connect()
end

local clock = os.clock
function sleep(n)
    local time = clock()
    while clock() - time <= n do
    end
end

function event()
    -- sleep for a second
    sleep(1)
end
