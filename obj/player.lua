--[[- ### game-object: player
@module obj.player
@author oxrusher(email: oxrusher@gmail.com)
@license 
--]]

module("obj", package.seeall)

require "obj.entity"
require "obj.def"
require "obj.client"

--- class player
player = class(obj.client)

--[[-
构造
@tparam userdata socket socket
@tparam string mac mac
@tparam number obj_type 类型
@tparam table props 属性集
@return nil
--]]
function player:init(socket, mac, obj_type, props)
    obj.client.init(self, socket, mac, obj_type, props)

    self.pos_x = 0
    self.pos_y = 0
    self.pos_z = 0
    self.region = 0
    self.stencil = 0
    self.level = 0
    self.id = 0
    self.equipments = {}
end

--[[-
解码
@tparam table data 编码
@return nil
--]]
function player:decode(data)
    assert(data)

    self.pos_x = data.position_x
    self.pos_y = data.position_y
    self.pos_z = data.position_z
    self.region = data.region
    self.stencil = data.stencil
    self.level = data.level
    self.id = data.id
    self.equipments = data.equit_list
end

--[[-
得到x坐标
@treturn number posx x坐标 
--]]
function player:get_posx()
    return self.pos_x
end

--[[-
得到y坐标
@treturn number posy y坐标
--]]
function player:get_posy()
    return self.pos_y
end

--[[-
得到z坐标
@treturn number posz z坐标
--]]
function player:get_posz()
    return self.pos_z
end

--[[-
设置x坐标
@tparam number x x坐标
@return nil
--]]
function player:set_posx(x)
    self.pos_x = x
end

--[[-
设置y坐标
@tparam number y y坐标
@return nil
--]] 
function player:set_posy(y)
    self.pos_y = y
end

--[[-
设置z坐标
@tparam number z z坐标
@return nil
--]] 
function player:set_posz(z)
    self.pos_z = z
end
