--[[- ### game-object: entity

* 所有游戏对象派生基类

@module obj.entity
@author oxrusher(email: oxrusher@gmail.com)
@license 
--]]

module("obj", package.seeall)

require "class"

--- class entity
entity = class()

--[[-
构造函数
@tparam number entity_type 类型
@tparam table props 属性集
@return nil
--]]
function entity:init(entity_type, props)
    self.type = entity_type
    self.props = {}
    for k,v in pairs(props) do
        self.props[k] = v            
    end
end

--[[-
设置属性
@tparam string name 属性名
@param value 属性值
@return 属性值
--]]
function entity:set_property(name, value)
    self.props[name] = value

    return true
end

--[[-
得到属性
@tparam string name 属性名
@return 属性值
--]]
function entity:get_property(name)
    return self.props[name]
end

--[[-
得到属性集
@treturn table props 属性集合
--]]
function entity:get_propertyset()
    return self.props
end

--[[-
设置属性集
@tparam table prop 属性集
@return nil
--]]
function entity:set_propertyset(prop)
    self.props = prop
end
