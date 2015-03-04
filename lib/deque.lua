--[[- ### deque
@module lib.deque
@author oxrusher(email: oxrusher@gmail.com)
@license 
--]]
module("lib.deque",package.seeall)

---
function new()
    return {
        first = 0, 
        last = -1,

        push_front = function(self,value)
            local first = self.first - 1
            self.first = first
            self[first] = value
        end;

        push_back = function(self,value)
            local last = self.last + 1
            self.last = last
            self[last] = value
        end;

        pop_front = function(self)
            local first = self.first
            if first > self.last then return end
            local value = self[first]
            self[first] = nil
            self.first = first + 1
            return value
        end;

        pop_back = function(self)
            local last = self.last
            if self.first > last then return end
            local value = self[last]
            self[last] = nil
            self.last = last - 1
            return value
        end;
    }
end
