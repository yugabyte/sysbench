-- Copyright (C) 2006-2018 Alexey Kopytov <akopytov@gmail.com>

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

-- -----------------------------------------------------------------------------
-- Common code for Geo-Partitioning
-- -----------------------------------------------------------------------------

function init_geopartition(con)

    rs_regions = con:query("SELECT cloud, region, count(*) FROM " ..
            " yb_servers() group by cloud, region order by cloud, region")
    if (rs_regions.nrows < 2) then
        error("Need to have more than one region " ..
                "in the universe for running geo-partitioning benchmark.")
    end
    clouds = {}
    regions = {}
    servers_in_regions = {}

    num_regions = rs_regions.nrows
    for i = 1, rs_regions.nrows do
        clouds[i], regions[i], servers_in_regions[i] = unpack(
                rs_regions:fetch_row(), 1, rs_regions.nfields)
    end
end


function get_geopartition_values(con)
    tblspaces = {}
    if (sysbench.opt.use_geopartitioning == false) then
        return
    end
    init_geopartition(con)
    for i = 1, num_regions do
        tblspaces[i] = string.format("%s_%s_tablespace",
                clouds[i]:gsub( "-", "_"), regions[i]:gsub( "-", "_"))
    end

    if (sysbench.opt.geopartitioned_queries == false) then
        start_idx = 1
        end_idx = sysbench.opt.table_size
        con:query("SET force_global_transaction=TRUE")
    else
        local rs_local = con:query("SELECT geo_partition, id FROM sbtest1 " ..
                "WHERE yb_is_local_table(tableoid) limit 1")
        geo_partition_col, id = unpack(rs_local:fetch_row(), 1, rs_local.nfields)
        values_tblspace = sysbench.opt.table_size/num_regions
        start_idx = 0
        end_idx = 0
        tblspace_idx = 1

        for i = 1, num_regions do
            if (geo_partition_col == tblspaces[i]) then
                start_idx = tblspace_idx
                if (i == num_regions) then
                    end_idx = sysbench.opt.table_size
                else
                    end_idx = tblspace_idx + values_tblspace - 1
                end
            end
            tblspace_idx = tblspace_idx + values_tblspace
        end
        if (start_idx == 0 or end_idx == 0) then
            error(string.format("geo_partition column string %s" ..
                    " doesn't match the table spaces", geo_partition_col))
        end
    end
end


function create_tablespaces(con)
    local tblspaces = {}
    if (sysbench.opt.use_geopartitioning == false) then
        return tblspaces
    end

    init_geopartition(con)
    for i = 1, rs_regions.nrows do
        if (tonumber(servers_in_regions[i]) < sysbench.opt.tblspace_num_replicas) then
            error(string.format("Region %s:%s has only %s server(s). Num replicas: %d ",
                    clouds[i], regions[i], servers_in_regions[i], sysbench.opt.tblspace_num_replicas))
        end
    end

    for i = 1, num_regions do
        local tblspace_name = string.format("%s_%s_tablespace",
                clouds[i]:gsub( "-", "_"), regions[i]:gsub( "-", "_"))
        tblspaces[i] = tblspace_name
        local tblspace_sql = string.format("CREATE TABLESPACE %s WITH( " ..
                "replica_placement='{\"num_replicas\": %d, \"placement_blocks\":[",
                tblspace_name, sysbench.opt.tblspace_num_replicas)
        print("Creating tablespace: " .. tblspace_name)
        rs_zones = con:query(string.format("SELECT cloud, region, zone, " ..
                "count(*) FROM yb_servers() where cloud = '%s'" ..
                " and region = '%s' group by cloud, region, "..
                "zone order by cloud, region, zone", clouds[i], regions[i]))
        if (rs_zones.nrows == sysbench.opt.tblspace_num_replicas) then
            for i = 1, rs_zones.nrows do
                if (i ~= 1) then
                    tblspace_sql = tblspace_sql .. ","
                end
                local cloud, region, zone, servers_in_zone = unpack(
                        rs_zones:fetch_row(), 1, rs_zones.nfields)
                tblspace_sql = tblspace_sql .. string.format(
                        "{\"cloud\":\"%s\",\"region\":\"%s\",\"zone\":\"%s\",\"min_num_replicas\":1}",
                        cloud, region, zone)
            end
        elseif (rs_zones.nrows == 1) then
            local cloud, region, zone, servers_in_zone = unpack(
                    rs_zones:fetch_row(), 1, rs_zones.nfields)
            tblspace_sql = tblspace_sql .. string.format(
                    "{\"cloud\":\"%s\",\"region\":\"%s\",\"zone\":\"%s\",\"min_num_replicas\":%d}",
                    cloud, region, zone, sysbench.opt.tblspace_num_replicas)
        else
            error(string.format("Number of zones in cloud %s:%s is %s and it "..
                    "does not match number of R %s",
                    cloud, region, rs_zones.nrows, sysbench.opt.tblspace_num_replicas))
        end
        tblspace_sql = tblspace_sql .. "]}')"
        con:query(tblspace_sql)
    end
    return tblspaces
end

function get_tablespaces(con)
    local tblspaces = {}
    if (sysbench.opt.use_geopartitioning == false) then
        return tblspaces
    end
    init_geopartition(con)
    for i = 1, num_regions do
        tblspaces[i] = string.format("%s_%s_tablespace",
                clouds[i]:gsub( "-", "_"), regions[i]:gsub( "-", "_"))
    end
    return tblspaces
end

function create_tables(con, tblspaces, table_num, id_def, engine_def,
                       create_table_options, id_index_def, range_key_string)
    if (sysbench.opt.use_geopartitioning == false) then
        return
    end
    query = string.format([[
               CREATE TABLE sbtest%d(
                 id %s,
                 k INTEGER DEFAULT '0' NOT NULL,
                 c CHAR(120) DEFAULT '' NOT NULL,
                 pad CHAR(60) DEFAULT '' NOT NULL,
                 geo_partition VARCHAR(120) DEFAULT '' NOT NULL,
                 %s (id %s, geo_partition)
               ) PARTITION BY  LIST (geo_partition) %s %s]],
            table_num, id_def, id_index_def, range_key_string, engine_def, create_table_options)
    con:query(query)

    for i = 1, #tblspaces do
        print (string.format("Creating parition table: sbtest%d_%s", table_num, tblspaces[i]))
        query = string.format([[
            CREATE TABLE sbtest%d_%s PARTITION OF sbtest%d (
              id,
              k,
              c,
              pad,
              geo_partition
            ) FOR VALUES IN ('%s') TABLESPACE %s %s]],
                table_num, tblspaces[i], table_num,
                tblspaces[i], tblspaces[i], engine_def)
        con:query(query)
    end

end

function create_index_gp(con, table_num, tblspaces)
    for i = 1, #tblspaces do
        print (string.format("Creating index parition: k_%d_%s", table_num, tblspaces[i]))
        con:query(string.format("CREATE INDEX k_%d_%s ON sbtest%d_%s(k) tablespace %s",
                table_num, tblspaces[i], table_num, tblspaces[i], tblspaces[i]))
    end
end

function bulk_load_inserts_gp(con, tblspaces, table_num)
    local c_val
    local pad_val
    local geo_partition
    local max_value_curr_tblspace = sysbench.opt.table_size/ #tblspaces
    local values_per_tblspace = sysbench.opt.table_size/ #tblspaces
    local curr_tblspace_idx = 1

    con:query("SET force_global_transaction=TRUE")
    if sysbench.opt.auto_inc then
        query = string.format("INSERT INTO sbtest%d(k, c, pad, geo_partition) VALUES",
                table_num)
    else
        query = string.format("INSERT INTO sbtest%d (id, k, c, pad, geo_partition) VALUES",
                table_num)
    end
    con:bulk_insert_init(query)

    for i = 1, sysbench.opt.table_size do
        if (i > max_value_curr_tblspace) then
            curr_tblspace_idx = curr_tblspace_idx + 1
            max_value_curr_tblspace = max_value_curr_tblspace + values_per_tblspace
        end
        c_val = get_c_value()
        pad_val = get_pad_value()
        geo_partition = tblspaces[curr_tblspace_idx]
        if (sysbench.opt.auto_inc) then
            query = string.format("(%d, '%s', '%s', '%s')",
                    sysbench.rand.default(max_value_curr_tblspace - values_per_tblspace + 1,
                            max_value_curr_tblspace),
                    c_val, pad_val, geo_partition)
        else
            query = string.format("(%d, %d, '%s', '%s', '%s')",
                    i,
                    sysbench.rand.default(max_value_curr_tblspace - values_per_tblspace + 1,
                            max_value_curr_tblspace),
                    c_val, pad_val, geo_partition)
        end

        con:bulk_insert_next(query)
    end
    con:bulk_insert_done()
end

function drop_tablespaces(con)
    if (sysbench.opt.use_geopartitioning == false) then
        return
    end
    init_geopartition(con)
    for i = 1, num_regions do
        local tblspace_name = string.format("%s_%s_tablespace",
                clouds[i]:gsub( "-", "_"), regions[i]:gsub( "-", "_"))
        print(string.format("Drop tablespace %s", tblspace_name))
        con:query(string.format("DROP TABLESPACE IF EXISTS %s", tblspace_name))
    end
end

