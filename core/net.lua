--[[- ### c# net-method wraper
@module core.net
@author oxrusher(email: oxrusher@gmail.com)
@license 
--]]

module("core.net", package.seeall)

require "sys.util"
require "core.event"

--[[-
@param ... 
@return nil
@usage init_net_config("core.net.on_connect", "core.net.error", "core.net.on_close", ...)
--]]
local function init_net_config(...)
    local cfg = {...}

    assert(#cfg == 3)

    gnet.config{
        connection = cfg[1];
        error = cfg[2];
        close = cfg[3];
    }
end

--[[-
加载文件初始化
@return nil
--]]
function init()
    -- init net config
    init_net_config("core.net.on_connect", 
                    "core.net.error",
                    "core.net.on_close")
end

--[[-
网络连接回调
@tparam userdata socket 连接socket对象
@return nil
--]]
function on_connect(socket)
    core.event.raise(EVENT_TYPE.NET, MESSAGE_TYPE.CONNECT, socket)
end

--[[-
网络中断回调
@tparam userdata socket 连接socket对象
@return nil
--]]
function on_close(socket)
    core.event.raise(EVENT_TYPE.NET, MESSAGE_TYPE.CLOSE, socket)
end

--[[-
网络错误回调
@tparam userdata socket 连接socket对象
@return nil
--]]
function error(socket)
    core.event.raise(EVENT_TYPE.NET, MESSAGE_TYPE.ERROR, socket)
end

--[[-
创建连接
@tparam string ip 地址
@tparam number port 端口
@treturn bool result 连接结果
--]]
function create_connection(ip, port)
    local socket = gnet.create()
    if socket then
        if string.len(ip)<1 then
			log_warn("invalid ip from server!")
		else
            if socket:is_connected() then
                socket:close()
            end

			return socket:asyc_connection(ip, port), socket
		end
    end

    return false
end

--[[-
关闭连接
@tparam userdata socket 连接socket对象
@return nil
--]]
function close_account_connection(socket)
	if socket:is_connected() then
		socket:close()
	end
end

init()
