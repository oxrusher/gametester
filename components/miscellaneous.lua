--[[- ### miscellaneous component
@module components.miscellaneous
@author oxrusher(email: oxrusher@gmail.com)
@license 
--]]

module("components", package.seeall)

require "sys.util"
require "class"
require "components.base"

--- MOVE组件
miscellaneous = class(components.base)

--[[-构造函数
@tparam table case 案例对象
@tparam table cfg 组件配置 
@return nil
@see gm
--]]
function miscellaneous:init(case, cfg, env)
    local args = cfg.args
    local name = cfg.com
	local times = cfg.times or 1
	local warn_time = cfg.args.warn_time
    self.warn_time = warn_time

    components.base.init(self, case, name, times, args, cfg, env)
end

--[[-执行函数
@tparam function on_succ 成功回调 
@tparam function on_failed 失败回调
@return nil
--]] 
function miscellaneous:run(on_succ, on_failed, entity)
    assert(type(on_succ) == "function")
    assert(type(on_failed) == "function")

    components.base.run(self)

    if self:determine_run_times() then
        local on_ping_succ = function()
            self:run(on_succ, on_failed, entity)
        end

        local on_ping_failed = function()
            on_failed()
            return true
        end

        self.owner:ping(self.warn_time or 1, on_ping_succ, on_ping_failed, entity)
    else
        on_succ()
    end
end
