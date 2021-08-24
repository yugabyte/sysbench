#!/usr/bin/env sysbench

-- ----------------------------------------------------------------------
-- Multi-row Insert OLTP benchmark
-- ----------------------------------------------------------------------

require("oltp_common")



function prepare_statements()
    if not sysbench.opt.skip_trx then
        prepare_begin()
        prepare_commit()
    end
    prepare_delete_inserts()
end

function event()
    if not sysbench.opt.skip_trx then
        begin()
    end

    execute_inserts()

    if not sysbench.opt.skip_trx then
        commit()
    end

    check_reconnect()


end
