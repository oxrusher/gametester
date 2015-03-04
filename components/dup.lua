--[[- ###duplicate component
@module components.dup
@author oxrusher(email: oxrusher@gmail.com)
@license 
--]]

module("components", package.seeall)

require "sys.util"
require "class"
require "components.base"

--- 副本组件
dup = class(components.base)

--[[-构造函数
@tparam table case 案例对象
@tparam table cfg 组件配置 
@return nil
@see dup
--]]
function dup:init(case, cfg, env)
    local args = cfg.args
    local name = cfg.com
    local times = cfg.times or 1

    components.base.init(self, case, name, times, args, cfg, env)
end

--[[-执行函数
@tparam function on_succ 成功回调 
@tparam function on_failed 失败回调
@return nil
--]]
function dup:run(on_succ, on_failed, entity)
    assert(type(on_succ) == "function")
    assert(type(on_failed) == "function")

    components.base.run(self)

    if self:determine_run_times() then
        for i,player in ipairs(self:get_owner():get_players()) do
            local on_player_move = function()
                player:start_talk("talks.player_move", talks.player_move)
            end

            player:connect(EVENT_TYPE.TIMER, on_player_move, math.random(1,2000), 1)
        end

        core.event.connect({}, EVENT_TYPE.TIMER, function(slot) self:run(on_succ, on_failed, entity) end, 2000, 1)
    else
       on_succ()
    end
end
