--[[- ###login component
@module components.login
@author oxrusher(email: oxrusher@gmail.com)
@license 
--]]
module("components", package.seeall)

require "sys.util"
require "class"
require "components.base"

--- LOGIN组件
login = class(components.base)

--- 已登录的数量
logined_count = 0

--[[-构造函数
@tparam table case 案例对象
@tparam table cfg 组件配置 
@return nil
@see gm
--]]
function login:init(case, cfg, env)
    local args = cfg.args
    self.ip = args.ip
    self.port = args.port
    self.connection = args.connection
    self.server_version = args.server_version

    local times = cfg.times or 1

    components.base.init(self, case, cfg.com, times, args, cfg, env)
end

--[[-执行函数
@tparam function on_succ 成功回调 
@tparam function on_failed 失败回调
@return nil
--]] 
function login:run(on_succ, on_failed, entity)
    assert(type(on_succ) == "function")
    assert(type(on_failed) == "function")

    local owner = self:get_owner()
    local env = self:get_env()

    components.base.run(self)

    if self:determine_run_times() then
        owner:release_entity(entity)

        local on_login_succ = function()
			logined_count = logined_count + 1
            self:run(on_succ, on_failed, entity)
        end

        local on_login_failed = function()
            owner:release_entity(entity)

            on_failed()
            return true
        end

        owner:login(on_login_succ, on_login_failed, env)
    else
        on_succ()
    end
end
