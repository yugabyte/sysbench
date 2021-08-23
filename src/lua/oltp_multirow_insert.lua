#!/usr/bin/env sysbench

-- ----------------------------------------------------------------------
-- Multi-row Insert OLTP benchmark
-- ----------------------------------------------------------------------

require("oltp_insert")

sysbench.cmdline.options.num_rows_in_insert =
{"Number of rows in a single insert statement", 10}

function event()
    local table_name = "sbtest" .. sysbench.rand.uniform(1, sysbench.opt.tables)
    local k_val, c_val, pad_val, query

    if (drv:name() == "pgsql" and sysbench.opt.auto_inc) then
        query = string.format("INSERT INTO %s (k, c, pad) VALUES ",
                table_name)
    else
        query = string.format("INSERT INTO %s (id, k, c, pad) VALUES ",
                table_name)
    end

    local j

    for j = 1, sysbench.opt.num_rows_in_insert do
        k_val = sysbench.rand.default(1, sysbench.opt.table_size)
        c_val = get_c_value()
        pad_val = get_pad_value()

        if (j ~= 1) then
            query = query .. ", "
        end

        if (drv:name() == "pgsql" and sysbench.opt.auto_inc) then
            query = string.format(query ..
                    " (%d, '%s', '%s')",
                    k_val, c_val, pad_val)
        else
            if (sysbench.opt.auto_inc) then
                i = 0
            else
                -- Convert a uint32_t value to SQL INT
                i = sysbench.rand.unique() - 2147483648
            end

            query = string.format(query ..
                    "(%d, %d, '%s', '%s')",
                    i, k_val, c_val, pad_val)
        end
    end
    con:query(query)
    check_reconnect()
end
