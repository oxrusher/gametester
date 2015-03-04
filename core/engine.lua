--[[- ### tester's powerful engine
@module core.engine
@author oxrusher(email: oxrusher@gmail.com)
@license 
--]]

module("core.engine", package.seeall)

require "sys.util"
require "core.case"
require "core.event_type"

--- 测试案例模版路径
local test_cases_direction = "test_case"

--- 进程所有运行的测试案例集
local cases = {}

--[[-
帧更新 脚本系统底层驱动
@return nil
--]]
function update()
    core.event.update()
end

--[[-
获取测试引擎updater
@return nil
--]]
function get_updater()
    assert(update)

    return update
end

--[[-
添加一个案例对象
@tparam table case_obj 案例对象
@treturn bool  result  结果
--]]
local function add(case_obj)
    assert(case_obj)

    cases[case_obj] = case_obj

    return true
end

--[[-
移除一个案例对象
@tparam table case_obj 案例对象
@treturn bool result 结果
--]]
function remove(case_obj)
    assert(case_obj)

    if cases[case_obj] and cases[case_obj] == case_obj then
        cases[case_obj] = nil
        return true
    end

    return false
end

--[[-
创建测试案例对象
@tparam string name 案例名
@tparam table cfg 案例配置
@param ... 案例详细信息
@treturn table case_obj 案例对象
--]]
local function create(name, cfg, ...)
    local case_obj = core.case(name, cfg, ...)

    if case_obj then
        add(case_obj)
    end

    return case_obj
end

--[[-
通过案例名称得到测试案例对象
@tparam string name 案例名
@treturn table case_obj 案例对象
--]]
function get_case(name)
    assert(type(name) == "string")

    local ret = {}
    for k,v in pairs(cases) do
        if v:get_name() == name then
            table.insert(ret, v)
        end
    end

    return ret
end

--[[-
通过案例类型得到测试案例对象集
@tparam number case_type 案例类型
@treturn table casts 案例对象表
--]]
local function get_case_by_type(case_type)
    assert(type(name) == "number")

    local ret = {}
    for k,v in pairs(cases) do
        if v:get_type() == case_type then
            table.insert(ret, v)
        end
    end

    return ret
end

--[[-
开启一个测试案例
@tparam table case 案例对象
@return nil
--]]
function start_case(case)
    assert(type(case) == "table")

    return case:start()
end

--[[-
得到所有测试案例配置
@treturn table cases 案例对象集
--]]
function get_all_case_cfg()
    local case_cfgs = sys.util.getfield(test_cases_direction,'table')
    if case_cfgs then
        local ret = {}
        for k,v in pairs(case_cfgs) do
            table.insert(ret, v)
        end

        return ret 
    end
end

--[[-
得到测试案例配置
@tparam string name 案例名称
@treturn table cfg 案例配置表
--]]
function get_case_cfg(name)
    local case_cfgs = sys.util.getfield(test_cases_direction,'table')
    if case_cfgs then

        return case_cfgs[name]
    end
end

--[[-
@tparam number case_type 案例测试类型
@return table cases 测试类型
--]]
function get_case_cfg_by_type(case_type)
    local ret = {}
    local case_cfgs = sys.util.getfield(test_cases_direction,'table')
    if case_cfgs then
        for k, v in pairs(case_cfgs) do
            if v.test_type and v.test_type == case_type then
                table.insert(ret, v)
            end
        end
    end

    return ret
end

--[[-
开始一个测试案例。 
@tparam string case_name 测试案例名
@treturn table case_obj 案例对象
--]]
function start(case_name, ...)
    local cfg = sys.util.getfield(test_cases_direction .. "." .. case_name, "table")
    local case_obj = create(case_name, cfg, ...)
    start_case(case_obj)

    return case_obj
end
