--[[- ### client profiler

## 使用方式：
* 初始化的时候，先注册你关心的函数以及在乎的超时时间(ms)

`

    require "sys.profiler"

    sys.profiler.threshold(10)

    sys.profiler.register("game.t")

    sys.profiler.register{"game.t", "game.op", "game.cmd"}

`

* 根据需求，逐帧或者定时获取分析报告，并打印到你需要的地方

`

    sys.profiler.report(print)
    sys.profiler.report(log)

`

@module profiler
@author oxrusher(email: oxrusher@gmail.com)
@license 
--]]

module("sys.profiler", package.seeall)

require "sys.util"

--- 已经注册的函数
local registers = {}

--- 已经注册的函数耗时记录 <like: { manager.test = 10000; } >
local records = {}

--- 设置函数执行超时时间(ms)
local register_time = 10

--[[-判断一个函数是否已经注册
@tparam function f 待分析的原始函数
@return ret 注册结果
--]]
local function determine(f)
    if registers[f] then
        return false
    end

    return true
end

--[[-获取分析报告
@tparam function f 打印方式
@treturn table records 分析报告
@see 
--]]
function report(f)
    assert(f)

    for k,v in ipairs(records) do
        f("profiler :" .. k .. " last time: " .. v)
    end

    return records
end

--[[- 清除报告
--]]
function clear()
    records = {}
end

--[[- 清除计时
@tparam number  t  阈值(ms)
--]]
function threshold(t)
    assert(type(t) == "number")

    register_time = t
end

--[[-记录一条记录
@tparam string name 函数名
@tparam number cost_time 消耗时间 
--]]
local function record(name, cost_time)
    records[name] = cost_time
end

--[[- 重置待分析函数
@tparam string name 待分析的原始函数名称
@tparam function f 待分析的原始函数对象 
--]]
local function reconnect(name,f)
    local new = function(...)
        local pre_time = sys.util.get_run_time()
        local ret = f(...) 
        local cur_time = sys.util.get_run_time()

        local cost_time = cur_time - pre_time
        if cost_time > register_time then
            record(name, cost_time)
        end

        return ret
    end

    sys.util.setfield(name, new)
end

--[[-注册一个函数到待分析列表
@tparam string name 待分析的原始函数名
@return ret 注册结果
--]]
local function register_func(name)
    assert(type(name) == "string")

    local f = sys.util.getfield(name, "function")
    assert(f)

    if determine(f) then
        reconnect(name,f)
        return true 
    end

    return false
end

--[[- 注册函数
@tparam function profiler_obj 待分析的原始函数或者集合
@usage  local ret = profiler.register("manager.test")
        local ret = profiler.register{"manager.test"; "manager.output";}
@return ret 注册结果
--]]
function register(profiler_obj)
    assert(profiler_obj )

    if type(profiler_obj) == "string" then
       register_func(profiler_obj) 
    elseif type(profiler_obj) == "table" then
        for k,v in pairs(profiler_obj) do
            register_func(v) 
        end
    else
        -- unknown type!
    end
end
