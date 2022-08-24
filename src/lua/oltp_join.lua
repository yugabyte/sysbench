#!/usr/bin/env sysbench
-- Copyright (C) 2006-2017 Alexey Kopytov <akopytov@gmail.com>

-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2 of the License, or
-- (at your option) any later version.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

-- ----------------------------------------------------------------------
-- OLTP Sum Scan
-- ----------------------------------------------------------------------

require("oltp_common")

function prepare_statements()
    prepare_heavy_join()
    prepare_light_join()
    prepare_delete_inserts()
    prepare_non_index_updates()
    prepare_for_each_table("deletes")

end

function event()
    if not sysbench.opt.skip_trx then
        begin()
    end
    execute_inserts()
    execute_non_index_updates(con)

    local tnum = sysbench.rand.uniform(1, sysbench.opt.tables)
    local id = sysbench.rand.default(1, sysbench.opt.table_size)

    param[tnum].deletes[1]:set(id)
    stmt[tnum].deletes:execute()

    if not sysbench.opt.skip_trx then
        commit()
    end
    execute_heavy_join()
    execute_light_join()
    check_reconnect()
end
