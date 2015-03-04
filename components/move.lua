--[[- ###move component
@module components.move
@author oxrusher(email: oxrusher@gmail.com)
@license 
--]]

module("components", package.seeall)

require "sys.util"
require "class"
require "components.base"

--- MOVE组件
move = class(components.base)

--[[-构造函数
@tparam table case 案例对象
@tparam table cfg 组件配置 
@return nil
@see gm
--]]
function move:init(case, cfg, env)
    local args = cfg.args
    local name = cfg.com
    local times = cfg.times or 1
    local range = cfg.args.range

    self.range = range

    components.base.init(self, case, name, times, args, cfg, env)
end

--[[-执行函数
@tparam function on_succ 成功回调 
@tparam function on_failed 失败回调
@return nil
--]] 
function move:run(on_succ, on_failed, entity)
    assert(type(on_succ) == "function")
    assert(type(on_failed) == "function")

    components.base.run(self)

    if self:determine_run_times() then
        local on_move_succ = function()
            self:run(on_succ, on_failed, entity)
        end

        local on_move_failed = function()
            on_failed()
            return true
        end

        self.owner:move(self.range or 1, on_move_succ, on_move_failed, entity)
    else
        on_succ()
    end
end
