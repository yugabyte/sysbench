#!/usr/bin/env sysbench

-- ----------------------------------------------------------------------
-- Multi-rows in a single Insert OLTP benchmark
-- ----------------------------------------------------------------------

require("oltp_common")

function prepare_statements()
   -- We do not use prepared statements here, but oltp_common.sh expects this
   -- function to be defined
end

function event()
    execute_multi_value_insert()
    check_reconnect()
end

