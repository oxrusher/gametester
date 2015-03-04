--[[- ### test case object
@module core.case
@author oxrusher(email: oxrusher@gmail.com)
@license 
--]]

module("core", package.seeall)

require "class"
require "deque"
require "core.net"
require "sys.util"
require "obj.player"

--- 组件名定义
local components_file_name = "components"

--- case类定义
case = class()

--- core.all_players, 包含当前进程所有客户端连接
all_players = all_players or {}

--[[-
获取一个客户端
@tparam userdata socket  socket对象
@treturn table player 获取对应的玩家
--]]
function get_player(socket)
    assert(socket)

    return all_players[socket] 
end

--[[-
单独创建案例组件
@tparam number index 组件ID 
@tparam table env 运行时环境
@return nil
--]]
function case:create_group_cpnts(index, env)
    local cfg = self.meta_cfg
    local process = cfg.process[index]
    assert(process)

    local cpnts = lib.deque.new() 

    for k,v in ipairs(process.sequence) do
        local tpl = cfg.components[v]
        assert(tpl)


        local name = components_file_name .. "." .. tpl.com
        local ret = require (name)
        if ret then
            local com_tpl = sys.util.getfield(name, "table")
            local com_obj = com_tpl(self, tpl, env)

            assert(com_obj)

            cpnts:push_front(com_obj)
        else
            log_error("can not find component file: " .. name)
        end
    end

    return cpnts
end

--[[-
@tparam table  cfg 组件模版配置
@tparam table  env 运行时环境
@return nil
--]]
function case:create_component(cfg, env)
    local t = {}
    
    assert(cfg.process)
    for k,v in ipairs(cfg.process) do
        local cpnts = lib.deque.new() 
        table.insert(t, {cpnts = cpnts, times = v.times})

        for index, handle_index in ipairs(v.sequence) do
            local tpl = cfg.components[handle_index]
            assert(tpl)

            local name = components_file_name .. "." .. tpl.com
            local ret = require (name)
            if ret then
                local com_tpl = sys.util.getfield(name, "table")
                local com_obj = com_tpl(self, tpl, env)

                assert(com_obj)

                cpnts:push_front(com_obj)
            else
                log_error("can not find component file: " .. name)
            end
        end
    end

    assert(#t > 0)
    return t
end

--[[-
初始化
@tparam string name 案例名称
@tparam table cfg 案例配置模版
@tparam string server_ip 服务器地址 
@tparam number server_port 服务器端口
@tparam number server_version 服务器版本号
@tparam number passport_begin 客户端连接起始数字标识
@tparam number passport_end 客户端连接结束数字标识
@return nil
--]]
function case:init(name, cfg, server_ip, server_port, server_version, passport_begin, passport_end)
    -- 配置模版
    self.meta_cfg = cfg

    -- 重连时间
    self.reconnect_time = 1000*60*1

    -- 启动时间
    self.begin_time = 0

    -- 名称
    self.name = name

    -- 测试服务器IP
    self.server_ip = server_ip

    -- 测试服务器连接端口
    self.server_port = server_port

    -- 服务器版本号
    self.server_version = server_version

    assert(type(passport_begin) == 'number')
    -- 连接开始数字标识
    self.passport_begin = passport_begin

    assert(type(passport_end) == 'number')
    -- 连接结束数字标识
    self.passport_end = passport_end

    assert(passport_begin <= passport_end)

    -- 类型
    assert(cfg.test_type)
    self.test_type = cfg.test_type

    -- 执行次数
    self.test_times = cfg.test_times or 1

    -- 包含客户端
    self.players = {}
end

--[[-
得到案例名称
@treturn string name 案例名称
--]]
function case:get_name()
    return self.name
end

--[[-
得到测试类型
案例类型，参见: 
@treturn number test_type 当前案例测试类型
--]]
function case:get_type()
    return self.test_type
end

--[[-
得到案例运行时长
@treturn number lasttime 当前案例运行时长
--]]
function case:get_time()
    return self.begin_time == 0 and 0 or sys.util.get_run_time() - self.begin_time 
end

--[[- 
运行一组测试组件
@return nil
--]]
function case:start_group_cpnt(index, obj, on_run_succ, on_run_failed, env)
    local cpnts = obj.cpnts
    local times = obj.times
    local run_times = 0
    local run, determine

    run = function()
        local current_cpnt = cpnts:pop_back()
        if current_cpnt then
            local entity = env.player
            local yield = function()
                -- 每执行完一个组件，就检查连接状态，断线，则重新执行当前案例
                if entity and entity:get_socket() and not entity:get_socket():is_connected() then
                    components.logined_count = components.logined_count - 1

                    return on_run_failed()
                end
                local interval = current_cpnt:get_interval()
                if interval then
                    return entity:connect(EVENT_TYPE.TIMER, run, interval, 1)
                else
                    return run()
                end
            end
          
            local on_succ = function()
                return yield()
            end
            -- 如果当个组件执行失败，则重新执行这个组件
            local on_failed = function()
                current_cpnt:set_run_times(current_cpnt:get_run_times() - 1)
                cpnts:push_back(current_cpnt) 
                return yield()
            end
            return current_cpnt:run(on_succ, on_failed, entity)
        else
            run_times = run_times + 1
            -- sys.util.snap() 
            if run_times >= times and times ~= 0 then
                return on_run_succ()
            else
                cpnts = self:create_group_cpnts(index, env)
                return run()
            end
        end
    end

    return run()
end

--[[- 
配置组件方式运行测试案例
按照条件，递归
@return nil
--]]
function case:start_cpnt()
    local mac_num = self.passport_end - self.passport_begin + 1
    local succ_count = 0

    local on_fini = function()
        succ_count = succ_count + 1

        if mac_num == succ_count then
            self:release()
            core.engine.remove(self)
            log_warn("test case: " .. self:get_name() .. "is finished.")
        end
    end

    for i = 1, mac_num, 1 do
        local run

        run = function()
			local mac_name = "i am robot : " .. tostring(self.passport_begin + i -1)
            local env = {mac = mac_name}
            local component_temp = self:create_component(self.meta_cfg, env)
            local k,v = next(component_temp)
            local on_succ, on_failed

            on_succ = function()
                k,v = next(component_temp, k)
                if k then
                    self:start_group_cpnt(k, v, on_succ, on_failed, env)
                else
                    return on_fini()
                end
            end

            -- 如果整个组件执行失败，则全部重新启动
            on_failed = function()
                self:release_entity(env.player)
                
                log_trace("mac: " .. env.player:get_name() .. " reconnect ...")

                return run()
            end
            
            if k then
                self:start_group_cpnt(k, v, on_succ, on_failed, env)
            else
                return on_fini()
            end
        end

        -- run()
        core.event.connect({}, EVENT_TYPE.TIMER, run, math.random(1000, 1*60*1000), 1) 
    end
end

--[[-
开始案例接口
@return nil
--]]
function case:start()
    log_debug("< test case:   " .. self:get_name() .. "> start ... ")

    -- 记录当前运行开始时间
    self.begin_time = sys.util.get_run_time()

    assert(self.test_type)

    local env = {}
    if self.test_type == "functional_test" then
        return self.meta_cfg.start(self, env)
    elseif self.test_type == "stress_test" then
        return self:start_cpnt()
    else
        log_error("unknown test type" .. self.test_type)
    end

    -- return self.meta_cfg.start(self, )
    --[[
    local co = coroutine.create(
            function(self)
                local ret, info = self.meta_cfg.start(self, env)
                if ret then
                    ret, info = self.meta_cfg.run(self, env)
                    if ret then
                        ret, info = self.meta_cfg.fini(self, env)
                        if ret then
                            log_debug("run test case: " .. self:get_name() .. " successful..")
                        else
                            log_error("run test case: " .. self:get_name() .. " in final stage failed. reason: " .. ( info or " none .."))
                        end
                    else
                        log_error("run test case: " .. self:get_name() .. " in test stage failed. reason: " .. ( info or " none .."))
                    end
                else
                    log_error("run test case: " .. self:get_name() .. " in begin stage failed. reason: " .. ( info or " none .."))
                end
            end
            )

    assert(type(co) == "thread")

    self.thread_id = co

    -- 记录当前运行开始时间
    self.begin_time = os.clock()

    local ret, info = coroutine.resume(co, self)
    if ret == false then
        log_fatal("start test case failed" .. ( type(info) == "string" and ( ", reason: " .. info ) or ""))
    end
    --]]
end

--[[-
获取案例包含player对象
@tparam string mac mac
@treturn table player 玩家对象
--]]
function case:get_player(mac)
    assert(mac)

    return self[mac]
end

--[[-
创建一个角色信息
@tparam userdata socket socket
@tparam string mac mac
@tparam table props 附加属性集
@treturn table player 创建的player对象
--]]
function case:create_player(socket, mac, props)
    local player = obj.player(socket, mac, OBJ_TYPE.PLAYER, props)

    -- add to case
    self.players[mac] = player

    -- add to globle 
    all_players[socket:raw()] = player

    return player
end

--[[-
得到当前案例包含的所有正常非掉线玩家
@treturn table plays={player1,player2, ...} 玩家列表
--]]
function case:get_players()
    local t = {}
    for k,v in pairs(self.players) do
        if v:get_socket():is_connected() then
            table.insert(t, v)
        end
    end

    return t
end

--[[-
施放一个案例中的玩家对象
@tparam table entity 玩家对象
@return nil
--]]
function case:release_entity(entity)
    if type(entity) == "table" then
        entity:disconnect_all()

        local socket = entity:get_socket()
        if socket then
            all_players[socket:raw()] = nil
            self.players[entity:get_mac()] = nil
            if socket:is_connected() then
                socket:close()
            end
            entity:set_socket()
            entity:set_propertyset()
        else
            -- log_fatal("error! release_entity failed, can not find its socket")
        end
    else
        -- log_warn("error! release_entity failed, invalid param : entity")
    end
end

--[[-
施放一个测试案例里面的游戏对象
@return nil
--]]
function case:release_all_entity()
    local entitys = self:get_players()
    for i, v in ipairs(entitys) do
        self:release_entity(v)
    end
end

--[[-
施放一个测试案例
@return nil
--]]
function case:release()
    self:release_all_entity()
    log_debug("< test case:   " .. self:get_name() .. ">  release... ")
end

--[[-
@tparam table entity 游戏对象,如player
@tparam userdata pre_socket 之前的socket
@tparam userdata cur_socket 当前的socket
@return nil
--]]
function case:reset_entity_connection(entity, pre_socket, cur_socket)
    entity:disconnect_all()
    entity:set_socket(cur_socket) 
    all_players[pre_socket:raw()] = nil
    all_players[cur_socket:raw()] = entity
end

--[[-
案例重置,包含重新初始化并执行
@return nil
--]]
function case:restart()
    self:release_all_entity()
    self:start()
end
