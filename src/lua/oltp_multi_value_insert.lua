#!/usr/bin/env sysbench

-- ----------------------------------------------------------------------
-- Multi-rows in a single Insert OLTP benchmark
-- ----------------------------------------------------------------------

require("oltp_common")


function thread_init()
    if (not sysbench.opt.auto_inc ) then
       error("Workload oltp_multi_value_insert only support auto-increment of Primary Key column i.e. (auto_inc=true)")
    end
    drv = sysbench.sql.driver()
    con = drv:connect()
end

function event()
    if (sysbench.opt.auto_inc) then
        execute_multi_value_insert()
        check_reconnect()
    else
        print("Workload oltp_multi_value_insert only support auto-increment of Primary Key column i.e. (auto_inc=true)")
        thread_done()
    end
end

function thread_done()
   con:disconnect()
end

