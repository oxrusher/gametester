module("test_case.login", package.seeall)

require "core.def"
require "setting.server_info"
require "talks.player_move"

test_type = "functional_test"

function start(self, env)
    local on_succ = function()
        local players = self:get_players()
        for i,player in ipairs(players) do
            local run = function(slot)
                player:start_talk("talks.player_move", talks.player_move)
            end
            player:connect(EVENT_TYPE.TIMER, run, 3000, 0)
        end

        log_debug("test_case.login,  on_succ! and restart case now")
        -- release(self, env)
    end

    local on_failed = function()
        log_debug("test_case.login,  on_failed! and restart login now")

        return false
    end

    self:login(on_succ, on_failed)
end

function release(self, env)
    self:release()
end
