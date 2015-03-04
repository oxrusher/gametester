--[[- ### define some tables for core-module refer
@module core.def
@author oxrusher(email: oxrusher@gmail.com)
@license 
--]]

module("core.def", package.seeall)


--- 测试类型定义
TEST_TYPE = TEST_TYPE or {
    FUNCTIONAL = {
        NONE = 0x00;
        LOGIN = 0x01;
        SKILL = 0x02;
        MOVE = 0x03;
        QUES = 0x04;
    };

    PRESSURE = {
        NONE = 0x00;
        LOGIN = 0x01;
        SKILL = 0x02;
        MOVE = 0x03;
        QUES = 0x04;
    };
}

_G.MESSAGE_TYPE = _G.MESSAGE_TYPE or {
    ERROR = -2;
    CLOSE = -1;
    CONNECT = 0;
}

--- talker 类型
CVST_TYPE = {
    QUEST = 0x01;
    REPLY = 0x02;
}

--- pvp type
PVP_OPER_TYPE = {
    ENTER = 0x01;
    LEAVE = 0x02;
    MOTION = 0x03;
}

--- pvp sub type
MOTION_TYPE = {
    START_MOVE = 0x02;
    STOP_MOVE = 0x03;
    SKILL = 0x04;
    SERVER_JUMP = 0x05;
    SERVER_SPASTICITY = 0x06;
}

--- pvp oper serial 
PVP_OPER_SERIAL = 0x63

--- for security flag
SECURITY_FLAG = "security"
