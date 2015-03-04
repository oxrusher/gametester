--[[- ### event module
@module core.event
@author oxrusher(email: oxrusher@gmail.com)
@license 
--]]

module("core.event", package.seeall)

require "class"
require "sys.util"

--- 事件槽列表
local slots = {}

--- 事件待删除列表
local del_slots = {}

--- 事件待添加列表
local add_slots = {}

--- 事件对象计数表
local slot_count = {}

--[[-
得到事件槽
@treturn table slots 事件槽
--]]
function get_slots()
    return slots
end

--[[-
每帧轮询事件

* 驱动定时器用

@return 事件对象
--]]
function update()

    return raise(EVENT_TYPE.TIMER)
end

--[[-
尝试删除当前帧需施放的事件对象
@return nil
--]]
local function try_destroy_slot()
    if del_slots then
        for k,v in pairs(del_slots) do
            local slot = v
            if slot.event_type == EVENT_TYPE.NET then
                remove_net_slot(slot)
            elseif slot.event_type == EVENT_TYPE.TIMER then
                remove_timer_slot(slot)
            else
                log_debug("try_destroy_slot error~  unknown event type: " .. slot.event_type)
            end
        end

        del_slots = nil

        ---TODO: 如果不删除entity对应的事件队列，会发生内存泄漏，这里需要显式的检查slot计数，然后施放
        for entity,count in pairs(slot_count) do
            if count == 0 then
                slot_count[entity] = nil 
                slots[entity] = nil
            end
        end
    end
end

--[[-
尝试添加slot到事件队列
@return nil
--]]
local function try_add_slot()
    if add_slots then
        for k,slot in ipairs(add_slots) do
            local entity = slot.owner
            local event_type = slot.event_type
            local msg_type = slot.msg_type

            if slot.event_type == EVENT_TYPE.NET then
                slots[entity] = slots[entity] or {}
                slots[entity][event_type] = slots[entity][event_type] or {}
                slots[entity][event_type][msg_type] = slots[entity][event_type][msg_type] or {}
                slots[entity][event_type][msg_type][slot] = slot
            elseif slot.event_type == EVENT_TYPE.TIMER then
                slots[entity] = slots[entity] or {}
                slots[entity][event_type] = slots[entity][event_type] or {}
                slots[entity][event_type][slot] = slot
            end
        end

        add_slots = nil
    end
end

--[[-
事件更新
@return nil
--]]
function update_event()    
    try_add_slot()
    try_destroy_slot()
end

--[[-
派发网络事件
@tparam string msg_type 消息类型
@tparam userdata socket socket
@param ... 触发事件详细信息
@return
--]]
function dispatch_net(msg_type, socket, ...)
    local player = core.get_player(socket:raw())
    if player then
        for entity,v in pairs(slots) do
            for evt_type, list in pairs(v) do
                if evt_type == EVENT_TYPE.NET and list[msg_type] then
                    for slot, slot in pairs(list[msg_type]) do
                        if socket:raw()== slot.socket:raw() then
                            local ret = slot.func(slot, ...)

                            slot.run_times = slot.run_times + 1
                            if slot.run_times >= slot.times or ret == true then
                                disconnect(slot)
                            end
                        end
                    end 
                end
            end
        end

        update_event()
    end
end

--[[-
派发定时器事件
@return nil
--]]
function dispatch_timer()
    for entity,v in pairs(slots) do
        for evt_type, list in pairs(v) do
            if evt_type == EVENT_TYPE.TIMER then
                for slot, slot in pairs(list) do
                    local current_time = sys.util.get_run_time()

                    if current_time - slot.last_time > slot.interval then
                        local ret = slot.func(slot)

                        slot.run_times = slot.run_times + 1
                        if ( slot.run_times >= slot.times and slot.times ~= 0) or ret == true then
                            disconnect(slot)
                        else
                            slot.last_time = sys.util.get_run_time()
                        end
                    end
                end
            end
        end
    end

    update_event()
end

--[[-
触发事件
@tparam number event_type 事件类型
@param  ... 派发详细信息
@return nil
--]]
function raise(event_type, ...)
    if event_type == EVENT_TYPE.NET then
        dispatch_net(...)
    elseif event_type == EVENT_TYPE.TIMER then
        dispatch_timer(...)
    else
        get_warn_log("invalid param: event_type.  function: core.event.raise")
    end
end

--[[-
创建事件对象
@tparam function func 回调函数
@tparam number times 调用次数
@tparam table owner 宿主，player, client, etc..
@tparam number event_type 事件类型
@tparam number arg  扩展参数，如果是网络事件，为网络消息类型，如果是定时器，为周期时间
@tparam userdata socket 网络消息对应的socket对象
@treturn table slot 事件对象
--]]
local function create_slot(func, times, owner, event_type, arg, socket)
    assert(func)
    assert(times)
    assert(owner)
    assert(event_type)

    local s = {
        func = func;
        socket = socket or 0;
        run_times = 0;
        owner = owner;
        event_type = event_type;
        msg_type = event_type == EVENT_TYPE.NET and arg or 0;
        interval = event_type == EVENT_TYPE.TIMER and arg or 0;
        times = times;
        last_time = sys.util.get_run_time();
    }

    slot_count[owner] = slot_count[owner] and slot_count[owner] + 1 or 1

    add_slots = add_slots or {}

    table.insert(add_slots, s)

    return s
end

--[[-
注册网络事件
@tparam table entity 游戏对象
@tparam number msg_type 消息类型
@tparam function func 回调函数
@tparam number times 回调次数
@tparam userdata socket socket对象
@treturn table slot 事件对象
--]]
function connect_net(entity, msg_type, func, times, socket)
    assert(entity)
    assert(msg_type)
    assert(func)
    assert(times)
    assert(socket)

    return create_slot(func, times, entity, EVENT_TYPE.NET, msg_type, socket)
end

--[[-
注册定时器
@tparam table entity 游戏对象
@tparam function func 回调函数
@tparam number interval 间隔
@tparam number times 回调次数
@treturn table slot 事件对象
--]]
function connect_timer(entity, func, interval, times)
    assert(entity)
    assert(func)
    assert(interval)
    assert(times)

    return create_slot(func, times, entity, EVENT_TYPE.TIMER, interval)
end

--[[-
注册接口

NOTE:

* 1. 注册定时器：
    * core.event.connect(player, EVENT_TYPE.TIMER, func, interval, times) 
* 2. 注册网络事件：
    * core.event.connect(player, EVENT_TYPE.NET, msg_type, func, times) 

@tparam table entity 游戏对象
@tparam number event_type 事件类型
@param ... 事件详细信息
@treturn table slot 事件对象
@usage core.event.connect({}, EVENT_TYPE.TIMER, function() end, 20000, 1)
--]]
function connect(entity, event_type, ...)
    assert(entity)
    assert(event_type)

    if event_type == EVENT_TYPE.NET then
        return connect_net(entity, ...)
    elseif event_type == EVENT_TYPE.TIMER then
        return connect_timer(entity, ...)
    else
        get_warn_log("invalid param: event_type.  function: core.event.connect")
    end
end

--[[-
注销网络事件
@tparam table slot 事件对象
@treturn bool result 删除结果
--]]
function remove_net_slot(slot)
    local entity = slot.owner
    local event_type = slot.event_type
    local msg_type = slot.msg_type


    if slot_count[entity] == nil then
        local x = 1
    end

    if slots[entity] then
        if slots[entity][event_type] then
            if slots[entity][event_type][msg_type] then
                if slots[entity][event_type][msg_type][slot] then
                   slots[entity][event_type][msg_type][slot] = nil 
                   slot_count[entity] = slot_count[entity] - 1
                   return true
                end
            end
        end
    end

    return false
end
 
--[[-
注销定时器
@tparam table slot 事件对象
@treturn bool result 删除结果
--]]
function remove_timer_slot(slot)
    local entity = slot.owner
    local event_type = slot.event_type

    if slot_count[entity] == nil then
        local x = 1
    end

    if slots[entity] then
        if slots[entity][event_type] then
            if slots[entity][event_type][slot] then
               slots[entity][event_type][slot] = nil 
               slot_count[entity] = slot_count[entity] - 1
               return true
            end
        end
    end

    return false
end

--[[-
注销事件接口
@tparam table slot 事件对象
@treturn bool result 删除结果
--]]
function disconnect(slot)
    assert(slot)

    del_slots = del_slots or {}

    del_slots[slot] = slot

    return true
end

--[[-
注销所有事件,慎用
@treturn bool result 结果
--]]
function disconnect_all()
    slots = {}

    return true
end

--[[-
得到指定游戏对象相关所有事件
@tparam table entity 游戏对象
@treturn table slots 事件集
--]]
function get_slots_by_entity(entity)
    local ret = {}

    if slots[entity] then
        for event_type, t in pairs(slots[entity]) do
            if event_type == EVENT_TYPE.NET then
                for msg_type, ts in pairs(t) do
                    for slot,slot in pairs(ts) do
                        table.insert(ret, slot)
                    end
                end
            elseif event_type == EVENT_TYPE.TIMER then
                for slot,slot in pairs(t) do
                    table.insert(ret, slot)
                end
            end
        end
    end

    return ret
end

--[[-
注销指定游戏对象所有事件
@tparam table entity 游戏对象
@treturn bool result 结果
--]]
function  disconnect_by_entity(entity)
    assert(entity)

    if slots[entity] then
        local ret = get_slots_by_entity(entity)
        for k, v in ipairs(ret) do
            disconnect(v)
        end
    else
        -- log_warn("disconnect_by_entity failed! can not find entity's events")
    end

    return true
end
