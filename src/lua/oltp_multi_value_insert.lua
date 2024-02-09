#!/usr/bin/env sysbench

-- ----------------------------------------------------------------------
-- Multi-rows in a single Insert OLTP benchmark
-- ----------------------------------------------------------------------

require("oltp_common")


function thread_init()
    if (not sysbench.opt.auto_inc ) then
       error("Workload oltp_multi_value_insert only supports auto-increment of primary key column i.e. (auto_inc=true)")
    end
    drv = sysbench.sql.driver()
    con = drv:connect()
end

function event()
    execute_multi_value_insert()
    check_reconnect()
end

function thread_done()
   con:disconnect()
end

