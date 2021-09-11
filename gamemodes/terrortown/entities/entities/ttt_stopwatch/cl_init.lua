include( "shared.lua" )

-- ConVar

CreateClientConVar("stopwatch_show_time", 0, true, false, "Determines whether to show the remaining time in seconds for the Stopwatch.", 0, 1)

-- Variables and tables

TTTStopwatch.Enabled = false

TTTStopwatch.Colors = {
    Yellow = Color(255,255,0),
    Green = Color(0,255,42),
    Red = Color(255,105,50), -- i know this isn't quite red but i don't feel like changing the variable name
    Black = Color(0,0,0),
    BackgroundBlack = Color(0,0,0,180),
    BackgroundGrey = Color(82,82,82,180)
}

TTTStopwatch.NextUse = 0
TTTStopwatch.NextCancel = 0

TTTStopwatch.RunningTime = 0
TTTStopwatch.Panel = {}

-- Helper functions

local function stopwatch_get_cooldown()
    return (GetConVar("stopwatch_cooldown"):GetInt())
end

local function stopwatch_get_cancel_cooldown()
    return (GetConVar("stopwatch_cancel_cooldown"):GetInt())
end

local function stopwatch_is_on_cooldown()
    return (CurTime() <= TTTStopwatch.NextUse)
end

local function stopwatch_can_cancel()
    return (CurTime() >= TTTStopwatch.NextCancel)
end

local function stopwatch_can_cancel_midair()
    if not LocalPlayer():OnGround() and not GetConVar("stopwatch_allow_cancelling_midair"):GetBool() then
        return false
    else return true end
end

local function stopwatch_show_seconds()
    return (GetConVar("stopwatch_show_time"):GetBool())
end

local function finish_stopwatch()
    if (timer.Exists("TTTStopwatch")) then
        timer.Remove("TTTStopwatch")
    end

    LocalPlayer():StopSound("stopwatch/running.wav")

    TTTStopwatch.Enabled = false
end

local function del_stopwatch()
    finish_stopwatch()
    TTTStopwatch.NextUse = 0
    TTTStopwatch.NextCancel = 0
end

-- Networking, main functions

net.Receive("Stopwatch_Enable", function( )

    TTTStopwatch.RunningTime = 10

    LocalPlayer():EmitSound("stopwatch/running.wav")

    TTTStopwatch.Enabled = true
    TTTStopwatch.NextCancel = CurTime() + stopwatch_get_cancel_cooldown()

    timer.Create("TTTStopwatch", 1, 0, function()
        if (TTTStopwatch.RunningTime == 0) then return end
        if (not TTTStopwatch.Enabled) then finish_stopwatch() end

        TTTStopwatch.RunningTime = TTTStopwatch.RunningTime - 1
    end)
end)

net.Receive("Stopwatch_Disable", function()

    finish_stopwatch()
    
    LocalPlayer():EmitSound("stopwatch/stop.wav")

    TTTStopwatch.NextUse = CurTime() + stopwatch_get_cooldown()

end)

net.Receive("Stopwatch_Remove", del_stopwatch)

net.Receive("Stopwatch_Death", del_stopwatch)

-- Hooks and panels

hook.Add("TTTEndRound", "Stopwatch_RoundFinish", del_stopwatch)

hook.Add("TTTBoughtItem", "Stopwatch_Panel", function(is_item, equipment)

    TTTStopwatch.Panel = {}

    local size = 145
    local x, y = ScrW() - 155, ScrH() / 2

    TTTStopwatch.Panel.Frame = vgui.Create("DPanel")
    TTTStopwatch.Panel.Frame:SetSize(size, size - 20)
    TTTStopwatch.Panel.Frame:SetPos(x, y)

    function TTTStopwatch.Panel.Frame:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, TTTStopwatch.Colors.BackgroundBlack)
        draw.RoundedBox(4, 2, 2, w - 4, h - 4, TTTStopwatch.Colors.BackgroundGrey)
    end

    function TTTStopwatch.Panel.Frame:Think()
        if (not LocalPlayer():HasEquipmentItem(EQUIP_STOPWATCH)) then
            self:Remove()
        -- else
        --     update_stopwatch_panel()
        end
    end

    local last_h = 5

    TTTStopwatch.Panel.Title = vgui.Create("DLabel", TTTStopwatch.Panel.Frame)
    TTTStopwatch.Panel.Title:SetColor(TTTStopwatch.Colors.Green)
    TTTStopwatch.Panel.Title:SetPos(0, last_h)
    TTTStopwatch.Panel.Title:CenterHorizontal()
    last_h = last_h + 12

    function TTTStopwatch.Panel.Title:Think()

        if not self then return end

        if (TTTStopwatch.Enabled) then

            self:SetText("Stopwatch running")
            self:SetColor(TTTStopwatch.Colors.Yellow)

        elseif (stopwatch_is_on_cooldown()) then

            self:SetText("Stopwatch not ready")
            self:SetColor(TTTStopwatch.Colors.Red)

        else
    
            self:SetText("Stopwatch ready")
            self:SetColor(TTTStopwatch.Colors.Green)

        end

        self:SizeToContents()
        self:CenterHorizontal()
    end

    local icon_mat = Material("vgui/ttt/ttt_stopwatch_icon")
    TTTStopwatch.Panel.Icon = vgui.Create("DImage", TTTStopwatch.Panel.Frame)
    TTTStopwatch.Panel.Icon:SetSize(75, 75)
    TTTStopwatch.Panel.Icon:Center()
    TTTStopwatch.Panel.Icon:SetMaterial(icon_mat)
    last_h = size - 40

    TTTStopwatch.Panel.Help = vgui.Create("DLabel", TTTStopwatch.Panel.Frame)
    TTTStopwatch.Panel.Help:SizeToContents()
    TTTStopwatch.Panel.Help:SetPos(0, last_h)
    TTTStopwatch.Panel.Help:CenterHorizontal()

    function TTTStopwatch.Panel.Help:Think()

        if not self then return end

        if (TTTStopwatch.Enabled) then
    
            if (stopwatch_can_cancel()) then
    
                if (not stopwatch_can_cancel_midair() or LocalPlayer():Crouching()) then
                    -- Not on ground / is crouching
    
                    self:SetText("Must be standing")
                    self:SetColor(TTTStopwatch.Colors.Red)
                else
    
                    -- On ground, tp available
                    self:SetText("USE + RELOAD to teleport")
                    self:SetColor(TTTStopwatch.Colors.Green)
                end
                
            else
    
                self:SetText(string.format("Wait %s seconds", math.ceil(TTTStopwatch.NextCancel - CurTime())))
                self:SetColor(TTTStopwatch.Colors.Red)
            end
        else

            if (stopwatch_is_on_cooldown()) then

                self:SetText(string.format("Wait %s seconds", math.ceil(TTTStopwatch.NextUse - CurTime())))
                self:SetColor(TTTStopwatch.Colors.Black)

            else

                if (not LocalPlayer():OnGround() or LocalPlayer():Crouching()) then

                    self:SetText("Must be standing")
                    self:SetColor(TTTStopwatch.Colors.Red)

                else

                    self:SetText("USE + RELOAD to enable")
                    self:SetColor(TTTStopwatch.Colors.Black)

                end

            end
        end

        self:SizeToContents()
        self:CenterHorizontal()
    end

    TTTStopwatch.Panel.Time = vgui.Create("DLabel", TTTStopwatch.Panel.Frame)
    TTTStopwatch.Panel.Time:SetColor(TTTStopwatch.Colors.Green)
    TTTStopwatch.Panel.Time:SetPos(8, 0)
    TTTStopwatch.Panel.Time:CenterVertical()
    TTTStopwatch.Panel.Time:SetText("")

    function TTTStopwatch.Panel.Time:Think()

        if not self then return end

        if (TTTStopwatch.Enabled) then
    
            if (stopwatch_show_seconds()) then
                self:SetText(TTTStopwatch.RunningTime)
                if (TTTStopwatch.RunningTime > 7) then
                    self:SetColor(TTTStopwatch.Colors.Green)
                elseif (TTTStopwatch.RunningTime > 3) then
                    self:SetColor(TTTStopwatch.Colors.Yellow)
                else
                    self:SetColor(TTTStopwatch.Colors.Red)
                end
            else
                self:SetText("")
            end
        else self:SetText("") end

        self:SizeToContents()
    end

    TTTStopwatch.Panel.Help:SetFont("Default")
    TTTStopwatch.Panel.Title:SetFont("Default")
    TTTStopwatch.Panel.Time:SetFont("Trebuchet24")

end)