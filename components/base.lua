--[[- ### base class about component
@module components.base
@author oxrusher(email: oxrusher@gmail.com)
@license 
--]]

module("components", package.seeall)

require "sys.util"
require "class"
require "core.press"

--- 所有测试组件基类
base = class()

--[[-构造函数
@tparam table case 案例对象
@tparam string name 组件名称
@tparam number times 运行次数
@tparam table args 自定义参数
@tparam table cfg 配置模版
@tparam table cfg 运行时环境
@usage  local login =  components.base(case, name, times, args, cfg)
@return nil
@see init
--]]
function base:init(case, name, times, args, cfg, env)
    self.owner = case
    self.name = name
    self.times = times or 1
    self.run_times = 0
    self.args = args
    self.meta_cfg = cfg
    self.interval = cfg.interval
    self.env = env
    self.events = {}
end

--[[- 得到当前组件运行时环境
@treturn table env 运行时环境
--]]
function base:get_env()

    return self.env
end

--[[- 得到当前组件执行成功等待时间
@treturn number interval 间隔时间
--]]
function base:get_interval()

    return self.interval
end

--[[- 得到当前组件名称
@treturn string name 组件名称
--]]
function base:get_name()

    return self.name
end

--[[-得到对应的测试案例对象
@treturn table owner 组件宿主
--]]
function base:get_owner()

    return self.owner
end

--[[-得到原始配置
@treturn table owner 组件宿主
--]]
function base:get_meta_cfg()

    return self.meta_cfg
end


--[[-当前组件执行次数
@treturn number run_times 组件执行次数
--]]
function base:get_run_times()

    return self.run_times
end

--[[-设置执行次数
@tparam number times 次数
@return true
--]]
function base:set_run_times(times)
    assert(times)

    self.run_times = times

    return true
end

--[[- 开始执行
@treturn bool result 结果
--]]
function base:run()
    self.run_times = self.run_times + 1

    return true
end

--[[-判断执行次数是否达到配置值
@treturn bool result 是否到达预期配置值
--]]
function base:determine_run_times()
    if self.times == 0 then
        return true
    else
        return self.run_times <= self.times
    end
end
