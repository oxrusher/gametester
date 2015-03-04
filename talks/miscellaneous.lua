module("talks", package.seeall)

--[[
-- NOTE
-- 主要使用心跳消息，测试服务器逻辑层延迟，用来检查服务器能承受的最大有效压力。
--]]
 
require "sys.util"
require "core.def"

miscellaneous = {
    {
        quest = {
            header = "nmiscellaneous.req_local_time";
            handle = function(entity, env)
                env.time_record = os.clock()
            return
            end
        };
    };
    {
        reply = {
            header = "miscellaneous.res_local_time";
            handle = function(entity, env, server_time)

            log_warn(" login gameserver player count: " .. components.logined_count or 0)
            local last_time = os.clock() - env.time_record
                if last_time > env.in_args.warn_time then
                    log_warn("ping proxy server used time:" .. last_time)
                end

                return true
            end
        }
    };
}
