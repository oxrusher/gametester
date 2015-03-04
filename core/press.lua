--[[- ### press-test interface  
@module core.press
@author oxrusher(email: oxrusher@gmail.com)
@license 
--]]


module("core", package.seeall)

require "sys.util"
require "core.case"
require "setting.skill"

--[[-
@tparam function on_succ 成功回调
@tparam function on_failed 失败回调
@tparam table env 组件运行时环境
@return nil
--]]
function case:login(on_succ, on_failed, cpenv)
    local server_version = self.server_version or core.def.SERVER_VERSION
    local ret, acc_socket = core.net.create_connection(self.server_ip, self.server_port)
    if ret then
        local player = self:create_player(acc_socket, cpenv.mac, {})
        cpenv.player = player

        local on_acc_connect = function(connect_event_slot)
            local on_login_acc_succ = function(entity, env)
                local ret, proxy_socket = core.net.create_connection(env.proxy_ip_address, env.proxy_port)
                if ret then 
                    self:reset_entity_connection(player, acc_socket, proxy_socket)

                    local on_proxy_connect = function(slot)
                        local on_login_proxy_succ = function(entity, env)

                            return type(on_succ) == "function" and on_succ()
                        end
                        
                        local on_login_proxy_failed = function(entity, env, err)
                            local pret = type(on_failed) == "function" and on_failed() 

                            if err then
                                log_error(err)
                            end
                        end

                        env.in_args = env.in_args or {}
                        env.in_args.server_version = server_version

                        player:start_talk("talks.login_proxy", talks.login_proxy, env, on_login_proxy_succ, on_login_proxy_failed)
                    end

                    player:connect(EVENT_TYPE.NET, MESSAGE_TYPE.CONNECT, on_proxy_connect, 1)
                else
                    on_failed()
                end
            end

            local on_login_acc_failed = function(entity, env, info)
                on_failed()
            end

            player:start_talk("talks.login_acc",talks.login_acc, nil, on_login_acc_succ, on_login_acc_failed)
        end

        player:connect(EVENT_TYPE.NET, MESSAGE_TYPE.CONNECT, on_acc_connect, 1)
    else
        on_failed()
    end
end

--[[-
批量请求移动
@tparam number range 移动范围
@tparam function on_succ 成功回调
@tparam function on_failed 失败回调
@tparam table entity 客户端对象
@return nil
--]]
function case:move(range, on_succ, on_failed, entity)
    local random_range = math.random(-range, range)
    local x = random_range
    local y = random_range
    local z = random_range

    return entity:start_talk("talks.player_move", talks.player_move, {in_args = {x = x, y = y, z = z}}, on_succ, on_failed)
end

--[[-
批量请求作弊
@tparam table args 输入参数
@tparam function on_succ 成功回调
@tparam function on_failed 失败回调
@tparam table entity 客户端对象
@return nil
@usage self:gm({add_money_num = 1, add_treasure_num = 1, add_currency_num = 1, add_stencil = 1000, add_stencil_num = 1}, function() end, function() end, entity)
--]]
function case:gm(args, on_succ, on_failed, entity)
    local add_money_num = args.add_money_num
    local add_treasure_num = args.add_treasure_num
    local add_currency_num = args.add_currency_num
    local add_stencil = args.add_stencil
    local add_stencil_num = args.add_stencil_num
    local level = args.level

    local in_args = {
        level = level,
        clear_type = clear_type,
        add_money_num = add_money_num,
        add_treasure_num = add_treasure_num,
        add_currency_num = add_currency_num,
        add_stencil = add_stencil,
        add_stencil_num = add_stencil_num,
        }

    return entity:start_talk("talks.gm", talks.gm, {in_args = in_args}, on_succ, on_failed)
end

--[[-
批量请求物品操作
@tparam table args 输入参数(包含物品操作类型)
@tparam function on_succ 成功回调
@tparam function on_failed 失败回调
@tparam table entity 客户端对象
@return nil
@usage self:pvp({oper_type = 1}, function() end, function() end, entity)
--]]
function case:pvp(args, on_succ, on_failed, entity)
    local oper_type = args.oper_type

    local talk_name
    local talk_mod
    local in_args
    if oper_type == 1 then
        talk_name = "talks.muliti_pvp_enter"
        talk_mod = talks.muliti_pvp_enter
    elseif oper_type == 2 then
        talk_name = "talks.muliti_pvp_leave"
        talk_mod = talks.muliti_pvp_leave
    elseif oper_type == 3 then
        talk_name = "talks.muliti_pvp_motion"
        talk_mod = talks.muliti_pvp_motion

        local players = self:get_players()
        local setting = setting.skill
        local skill_id = 40000000 -- setting[math.random(1, #setting)]
        local target = players[math.random(1, #players)]
        local target_id = target.id or 0
        local orientation = math.random(0, math.pi)
        local center_pos = args.center_pos or {31,5,33}
        local move_range = args.move_range or 5
        local range = math.random(-move_range, move_range)
	end
end

--[[-
@tparam table args 输入参数(包含物品操作类型)
@tparam function on_succ 成功回调
@tparam function on_failed 失败回调
@tparam table entity 客户端对象
@return nil
@usage self:item({item_oper_type = 1, vessel_type = 1, vessel_id= 1, equip_id= 1, count= 1}, function() end, function() end, entity)
--]]
function case:security(args, on_succ, on_failed, entity)
    local oper_type = args.item_oper_type
    local msg_count_per_second = args.msg_count_per_second
    local max_args = args.max_args 
    
    local in_args = {
        max_args = max_args,
        }

    for i = 1, msg_count_per_second, 1 do
        return entity:start_talk("talks.security", talks.security, {in_args = in_args}, on_succ, on_failed)
    end
end

--[[-

ping:

* 1. 目的
	* 使用心跳消息检查服务器存活状态

@tparam table args 输入参数
@tparam function on_succ 成功回调
@tparam function on_failed 失败回调
@tparam table entity 客户端对象
@return nil
@usage self:item({item_oper_type = 1, vessel_type = 1, vessel_id= 1, equip_id= 1, count= 1}, function() end, function() end, entity)
--]]
function case:ping(warn_time, on_succ, on_failed, entity)
    local in_args = {
        warn_time = warn_time,
        }

	return entity:start_talk("talks.miscellaneous", talks.miscellaneous, {in_args = in_args}, on_succ, on_failed)
end
