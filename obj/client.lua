--[[- ### game-object: client
@module obj.client
@author oxrusher(email: oxrusher@gmail.com)
@license 
--]]
module("obj", package.seeall)

require "obj.entity"
require "obj.def"
require "core.talker"

--- class client
client = class(obj.entity)

--[[-
构造
@tparam userdata socket socket
@tparam string mac mac
@tparam number obj_type 类型
@tparam table props 属性
@return nil
--]]
function client:init(socket, mac, obj_type, props)
    obj.entity.init(self, obj_type, props)

    self.socket = socket
    self.mac = mac
end

--[[-
获取mac
@treturn string mac mac
--]]
function client:get_mac()
    return self.mac
end

--[[-
获取名字
@treturn string mac mac
--]]
function client:get_name()
    return self.mac
end

--[[-
获取socket对象
@treturn userdata socket socket
--]]
function client:get_socket()
    return self.socket
end

--[[-
设置socket对象
@tparam userdata socket socket
@return nil
--]]
function client:set_socket(socket)
	self.pre_socket = self.socket
    self.socket = socket
end


--[[-
获取socket对象
@treturn userdata socket socket
--]]
function client:get_socket()
    return self.socket
end

--[[-
注册事件
@tparam number event_type 事件类型
@param ... 
@treturn table slot 事件对象
--]]
function client:connect(event_type, ... )
    local args = {...}
    if event_type == EVENT_TYPE.NET then
        assert(self.socket)

        args[4] = self.socket
    end

    return core.event.connect(self, event_type, unpack(args))
end

--[[-
删除事件
@tparam table slot 事件对象
@treturn bool result 结果
--]]
function client:disconnect(slot)
    return core.event.disconnect(slot)
end

--[[-
删除所有关联的事件
@treturn bool result 结果
--]]
function client:disconnect_all()
    return core.event.disconnect_by_entity(self)
end

--[[-
发送消息
@tparam string sender_name 消息头
@param ... 消息内容
@return nil
@usage player:send("gm.add_money", 1000)
--]]
function client:send(sender_name, ...)
    if self.socket then
        --[[
        send_msg_count = send_msg_count or 0
        send_msg_count = send_msg_count + 1
        log_trace("send message count : " .. send_msg_count)
        --]]

        -- send security message by default
        -- sys.util.send_random_msg(self.socket, sys.util.get_random_args(5))

        local sender 
        if sender_name == core.def.SECURITY_FLAG then
            return sys.util.send_random_msg(self.socket, ...)
        else
            sender = sys.util.getfield(sender_name, 'function')

            if sender then
                return sender(self.socket, ...)
            else
                log_warn("send message failed!  sender name:" .. sender_name)
            end
        end
    else
        log_fatal("send message failed!  sender name:" .. sender_name .. " , reason: invalid socket obj!")
    end
end

--[[-
开始会话
@tparam string name 会话名  
@tparam table cfg 会话配置  
@tparam table env 会话初始化环境  
@tparam function on_succ  成功回调 
@tparam function on_failed 失败回调 
@treturn table talker 会话对象
--]]
function client:start_talk(name, cfg, env, on_succ, on_failed)
    local on_client_succ = function(...)
        if type(on_succ) == "function" then 
            on_succ(...)
        end
    end

    local on_client_failed = function(...)
        if type(on_failed) == "function" then 
            on_failed(...)
        end
    end

    local talker = core.talker(name, self, cfg, env, on_client_succ, on_client_failed)

    return talker:start()
end
