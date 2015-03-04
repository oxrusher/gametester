--[[- ### sys.timer
暂未使用
@module sys.timer
@author oxrusher(email: oxrusher@gmail.com)
@license 
--]]

module("sys.timer", package.seeall)

--[[-
帧更新
@return nil
--]]
function update(timer_list)
    assert(timer_list)

    for entity,v in pairs(timer_list) do
        for evt_type, list in pairs(v) do
            for slot, slot in pairs(list) do
                local current_time = sys.util.get_run_time()

                if current_time - slot.last_time > slot.interval then
                   --core.event.raise(EVENT_TYPE.TIMER, MESSAGE_TYPE.ERROR, socket)

                    slot.func(entity)

                    slot.run_times = slot.run_times + 1

                    if slot.run_times >= slot.times then
                        timer_list[entity][evt_type][slot] = nil
                    else
                        slot.last_time = current_time
                    end
                end
            end
        end
    end
end
