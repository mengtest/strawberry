local region = require "chestnut.mahjongroom.region"
local hutype = require "chestnut.mahjongroom.hutype"
local jiaotype = require "chestnut.mahjongroom.jiaotype"

local m = {}

m[hutype.PINGHU]          = 1
m[hutype.DUIDUIHU]        = 2
m[hutype.QINGYISE]        = 4
m[hutype.DAIYAOJIU]       = 4 
m[hutype.QIDUI]           = 4
m[hutype.JINGOUDIAO]      = 4
m[hutype.QINGDUIDUI]      = 8
m[hutype.LONGQIDUI]       = 16 
m[hutype.QINGQIDUI]       = 16 
m[hutype.QINGYAOJIU]      = 16 
m[hutype.JIANGJINGOUDIAO] = 16 
m[hutype.QINGJINGOUDIAO]  = 16 
m[hutype.TIANHU]          = 32 
m[hutype.DIHU]            = 32 
m[hutype.QINGLONGQIDUI]   = 32 
m[hutype.SHIBALUOHAN]     = 64 
m[hutype.QINGSHIBALUOHAN] = 256

return m