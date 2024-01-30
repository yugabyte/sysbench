

require("oltp_common")

sysbench.cmdline.commands.prepare = {
   function ()
      if (not sysbench.opt.auto_inc) then
         -- Create empty tables on prepare when --auto-inc is off, since IDs
         -- generated on prepare may collide later with values generated by
         -- sysbench.rand.unique()
         sysbench.opt.table_size=0
      end

      cmd_create()
      --cmd_prepare()
   end,
   sysbench.cmdline.PARALLEL_COMMAND
}

function prepare_statements()
   -- We do not use prepared statements here, but oltp_common.sh expects this
   -- function to be defined
end
