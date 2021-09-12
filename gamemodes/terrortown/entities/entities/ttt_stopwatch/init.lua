AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include( "shared.lua" )

-- ConVars
CreateConVar("stopwatch_on_fail", "cancel", FCVAR_ARCHIVE, "Determines what will happen when a user tries to use the Stopwatch and there's someone in the way. 'cancel' will cancel the teleport, 'kill_user' will kill the teleporter, and 'kill_blocker' will kill the player in the way.")

TTTStopwatch.OnFail = GetConVar("stopwatch_on_fail"):GetString()

cvars.AddChangeCallback("stopwatch_on_fail", function(convar, old, new)
    local valid = {
        ["cancel"] = true,
        ["kill_user"] = true,
        ["kill_blocker"] = true
    }

    if (not valid[new]) then
        MsgC(Color(255,96,96), "Valid values for stopwatch_on_fail are: 'cancel' - 'kill_user' - 'kill_blocker'\n")
        GetConVar("stopwatch_on_fail"):SetString(old)
    else
        TTTStopwatch.OnFail = new
    end

end, "Stopwatch_ConVar_Callback")

CreateConVar("stopwatch_cooldown", 30, FCVAR_ARCHIVE, "Cooldown in seconds between Stopwatch uses.", 1)

CreateConVar("stopwatch_cancel_cooldown", 3, FCVAR_ARCHIVE, "Time that has to pass after activating Stopwatch for the player to be able to 'cancel' the teleport.", 0)

CreateConVar("stopwatch_allow_cancelling_midair", 1, FCVAR_ARCHIVE, "Determines whether players can cancel the Stopwatch teleport while in mid-air.", 0, 1)

-- 12/9/21
CreateConVar("stopwatch_nofall", 1, FCVAR_ARCHIVE, "Determines whether the Stopwatch negates fall damage when activated.", 0, 1)

-- Net strings
util.AddNetworkString( "Stopwatch_Enable" )
util.AddNetworkString( "Stopwatch_Disable" )
util.AddNetworkString( "Stopwatch_Remove" )
util.AddNetworkString( "Stopwatch_Death" )

-- Meta
local plymeta = FindMetaTable("Player")

-- Helper functions
function plymeta:CanUseStopwatch()
    if (self:OnGround() and not self:Crouching() and ((not self.Stopwatch_NextUse) or (CurTime() >= self.Stopwatch_NextUse))) then return true end
end

function plymeta:CanCancelStopwatchMidair()
    if (not self:OnGround() and not GetConVar("stopwatch_allow_cancelling_midair"):GetBool()) then
        return false
    else return true end
end

function plymeta:CanCancelStopwatch()
    return (CurTime() >= self.Stopwatch_CancelTime and self:CanCancelStopwatchMidair())
end

function plymeta:CheckForStopwatchTimer()
    local timer_name = "Stopwatch_" .. self:SteamID()
    if (timer.Exists(timer_name)) then timer.Remove(timer_name) end
end

function plymeta:RemoveStopwatch()
    self:CheckForStopwatchTimer()

    self.Stopwatch_Enabled = false
    self.Stopwatch_NoFall = false
    self.Stopwatch_EnabledOnRound = nil
    self.Stopwatch_NextUse = 0
    self.Stopwatch_Pos = 0
    self.Stopwatch_BBox = nil
end

local function current_round()
    return (GetConVar("ttt_round_limit"):GetInt() - GetGlobalInt("ttt_rounds_left") + 1)
end

local function stopwatch_get_cooldown()
    return (GetConVar("stopwatch_cooldown"):GetInt())
end

local function stopwatch_get_cancel_cooldown()
    return (GetConVar("stopwatch_cancel_cooldown"):GetInt())
end

local function stopwatch_is_nofall_on()
    return (GetConVar("stopwatch_nofall"):GetBool())
end

-- Main functions

local function stopwatch_check_tppos(ply)

    local tr = util.TraceHull( {
        start = ply.Stopwatch_Pos,
        endpos = ply.Stopwatch_Pos,
        mins = ply.Stopwatch_BBox.mins,
        maxs = ply.Stopwatch_BBox.maxs,
        collisiongroup = COLLISION_GROUP_PLAYER,
        filter = ply
    } )

    local data = {
        successful = false,
        blocker = false
    }

    if (tr.Hit and tr.Entity:IsValid() and tr.Entity:IsPlayer()) then
        data.successful = false
        data.blocker = tr.Entity
    else
        data.successful = true
    end

    return data

end

local function stopwatch_finish(ply)
    local timer_name = "Stopwatch_" .. ply:SteamID()

    if (ply.Stopwatch_EnabledOnRound ~= current_round()) then ply:RemoveStopwatch() return end

    ply:CheckForStopwatchTimer()

    ply.Stopwatch_Enabled = false
    ply.Stopwatch_EnabledOnRound = nil
    ply.Stopwatch_NextUse = CurTime() + stopwatch_get_cooldown()

    local data = stopwatch_check_tppos(ply)
    local pos = ply:GetPos()

    net.Start("Stopwatch_Disable")
    net.Send(ply)

    if (data.successful) then

        sound.Play(TTTStopwatch.Sounds[math.Round(math.Rand(1, #TTTStopwatch.Sounds))], pos, 75, math.Round(math.Rand(65,125)))

        if (stopwatch_is_nofall_on()) then
            -- One more second of fall damage invulnerability
            timer.Simple(1, function() ply.Stopwatch_NoFall = false end)

            ply:SetPos(ply.Stopwatch_Pos)
        end

    else

        sound.Play(TTTStopwatch.Sounds[math.Round(math.Rand(1, #TTTStopwatch.Sounds))], pos, 75, math.Round(math.Rand(65,125)))

        if (TTTStopwatch.OnFail == "kill_blocker") then
            ply:SetPos(ply.Stopwatch_Pos)
            data.blocker:TakeDamage(data.blocker:Health() * 2, ply, ply)
        elseif (TTTStopwatch.OnFail == "kill_user") then
            ply:SetPos(ply.Stopwatch_Pos)
            ply:TakeDamage(ply:Health() * 2, data.blocker, data.blocker)
        end
        
    end

    
end

local function stopwatch_enable(ply)
    if (GetRoundState() ~= ROUND_ACTIVE) then return end

    net.Start( "Stopwatch_Enable" )
    net.Send( ply )

    ply.Stopwatch_Enabled = true
    ply.Stopwatch_CancelTime = CurTime() + stopwatch_get_cancel_cooldown()
    if (stopwatch_is_nofall_on()) then ply.Stopwatch_NoFall = true end

    ply.Stopwatch_EnabledOnRound = current_round()

    ply.Stopwatch_Pos = ply:GetPos()

    ply.Stopwatch_BBox = {
        mins = ply:OBBMins(),
        maxs = ply:OBBMaxs()
    }

    timer.Create("Stopwatch_" .. ply:SteamID(), 10, 1, function()
        if (GetRoundState() ~= ROUND_ACTIVE) then ply:RemoveStopwatch() return end
        stopwatch_finish(ply)
    end)
end

-- Hooks -w-

hook.Add("EntityTakeDamage", "Stopwatch_Damage", function(ent, dmg)
    if (stopwatch_is_nofall_on() and ent:IsValid() and ent:IsPlayer() and ent:HasEquipmentItem(EQUIP_STOPWATCH) and ent.Stopwatch_NoFall and dmg:IsFallDamage()) then
        return true
    end
end)

hook.Add("KeyPress", "Stopwatch_KeyPress", function(ply, key)
    -- If player has Stopwatch and presses both keys
    if (ply:HasEquipmentItem(EQUIP_STOPWATCH)) and (ply:KeyDown(IN_USE) and ply:KeyDown(IN_RELOAD)) then

        -- If player is touching the ground and is not on cooldown
        if (ply.Stopwatch_Enabled and ply:CanCancelStopwatch()) then stopwatch_finish(ply)
        elseif ((not ply.Stopwatch_Enabled) and ply:CanUseStopwatch()) then stopwatch_enable(ply) end

    end
end)

hook.Add("TTTOrderedEquipment", "Stopwatch_Init", function(ply, equip, is_item)
    if (ply:IsValid() and is_item and (equip == EQUIP_STOPWATCH)) then
        ply.Stopwatch_Enabled = false
        ply.Stopwatch_NoFall = false
    end
end)

hook.Add("TTTEndRound", "Stopwatch_FinishAll", function()
    for k,v in pairs(player.GetAll()) do
        v:RemoveStopwatch()
    end
end)

hook.Add("DoPlayerDeath", "Stopwatch_Death", function(ply)
    ply:RemoveStopwatch()
    net.Start("Stopwatch_Death")
    net.Send(ply)
end)