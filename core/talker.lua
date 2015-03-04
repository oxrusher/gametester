module("core", package.seeall)

require "class"
require "sys.util"
require "core.def"

--- class talker
talker = class()

--- 每个talker节点超时时间
local protect_time_per_node = 2

--[[-
构造
@tparam string name taker名称
@tparam table entity 宿主
@tparam table cfg 配置表
@tparam table env 执行环境 
@tparam function on_succ  成功回调
@tparam function on_failed  失败回调
@return nil
--]]
function talker:init(name, entity, cfg, env, on_succ, on_failed)
    self.begin_time = 0
    self.name = name
    self.entity = entity
    self.cfg = cfg
    self.on_succ = on_succ
    self.on_failed = on_failed
    self.env = env or {}
end

--[[-
开启一次会话
@return nil
--]]
function talker:start()
    assert(self.cfg)

    local stage = 1
    local cfg = self.cfg
    local player = self.entity
    local on_succ, on_failed = self.on_succ, self.on_failed
    local run, echo, make, increace, disconnect, determine, on_timeout
    local net_event_id, timer_id
    local protect_time = #cfg*1000*protect_time_per_node

    run = function()
        local node = cfg[stage]
        if node then
            make(node)

            return false
        end

        disconnect()

        return type(on_succ) == "function" and  on_succ(player, self.env)
    end

    increace = function()
        stage = stage + 1

        return true
    end

    disconnect = function()

        return ( timer_id and player:disconnect(timer_id) ) or ( net_event_id and player:disconnect(net_event_id) )
    end

    determine = function(node)
        local condition = node.condition
        if condition and type(condition) == "function" and condition(player, self.env) == false then
            return false
        end

        return true
    end

    make = function(node)
        if determine(node) then
            if node.reply then
                net_event_id = player:connect(EVENT_TYPE.NET, MESSAGE_TYPE[node.reply.header], echo, 1)

                return false
            elseif node.quest then
                player:send(node.quest.header, node.quest.handle(player, self.env))
            end
        end

        return increace() and run()
    end

    echo = function(slot, ...)
        local node = cfg[stage]
        local ret, err = node.reply.handle(player, self.env, ...)
        if ret then
            return increace() and run()
        end

        disconnect()

        return type(on_failed) == "function" and on_failed(player, self.env, err)
    end

    on_timeout = function(slot, ...)
        disconnect()

        return type(on_failed) == "function" and on_failed(player, self.env, "talker: " .. self.name .. " was interrupted by protect time method ! last stage id :" .. stage)
    end

    timer_id = player:connect(EVENT_TYPE.TIMER, on_timeout, protect_time, 1)

    return run()
end

--[[-
关闭会话
@return nil
--]]
function talker:release()
    self.entity = nil
    self.cfg = nil
    self.on_succ = nil
    self.on_failed = nil
    self.env = nil
end
