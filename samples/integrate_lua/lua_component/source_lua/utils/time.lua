---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by captain.
--- DateTime: 5/26/2022 12:03 AM
---

require("lua_extension")

Time={

}

--- 获取游戏运行时间
function Time:TimeSinceStartup()
    Cpp.Time.TimeSinceStartup()
end

function Time:delta_time()
    Cpp.Time.delta_time()
end