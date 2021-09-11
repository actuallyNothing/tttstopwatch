--[[
    TTT Stopwatch

    Traitor equipment made by actuallyNothing,
    based on the old X-Mark weapon by Tommy228.

    Icon made with works by Icons8
    https://icons8.com/icon/KU6Lo3dhTlxw/stopwatch
    https://icons8.com/icon/siZRPu4tKzwC/stopwatch

    Contact:
    https://steamcommunity.com/id/actuallyNothing/
    https://github.com/actuallyNothing/
]]

TTTStopwatch = {}

if (SERVER) then
    TTTStopwatch.Sounds = {
        [1] = "stopwatch/teleport1.wav",
        [2] = "stopwatch/teleport2.ogg",
        [3] = "stopwatch/teleport3.wav"
    }
    
    for _, v in pairs(TTTStopwatch.Sounds) do
        resource.AddFile("sound/" .. v)
    end
    
    resource.AddSingleFile("sound/stopwatch/running.wav")
    resource.AddSingleFile("sound/stopwatch/stop.wav")
    resource.AddFile("materials/vgui/ttt/ttt_stopwatch_icon.vmt")
end

if (not EQUIP_STOPWATCH) then
    EQUIP_STOPWATCH = ( GenerateNewEquipmentID and GenerateNewEquipmentID() ) or 128

    local stopwatch = {
        id       = EQUIP_STOPWATCH,
        type     = "item_passive",
        material = "vgui/ttt/ttt_stopwatch_icon",
        name     = "Stopwatch",
        desc     = "Press E + R to mark your current position, then\nafter 10 seconds you will be brought back to it.\nYou can teleport early by activating\nthe Stopwatch again."
    }

    table.insert( EquipmentItems[ ROLE_TRAITOR ], stopwatch )
end
