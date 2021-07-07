
function AddBlip( pos , type , color , alpha, number , scale ,text)

    local blip = AddBlipForCoord(pos.x,pos.y,pos.z)
    SetBlipSprite(blip, type)
    SetBlipColour(blip, color)
    SetBlipAlpha(blip, alpha)
    SetBlipScale(blip, scale or 1.0)

    -- SetBlipRoute(blip, true)
    -- SetBlipRouteColour(blip, color)
    
    if number ~= nil then
        ShowNumberOnBlip(blip,number)
    end

    if text ~= nil then
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandSetBlipName(blip)
    end
    
    return blip
end

function AddCheckpoint(_type,reverse,src,dest,ra,r,g,b,a)
    a = a or 255

    return CreateCheckpoint(_type, src.x,src.y,src.z, dest.x,dest.y,dest.z, ra,r,g,b,a, reverse)
end

function DrawText(text , x,y,size, r,g,b,alpha, font, right,width,center,outline)
    alpha = alpha or 255
    local x_offset , y_offset = 0 , 0
    if center == true then 
        SetTextJustification(0)
    end
    if right then
		SetTextWrap(x - width, x)
		SetTextRightJustify(true)
	end

    SetTextFont(font)
    SetTextScale(0.0, size)
    SetTextColour(r, g, b, alpha)
    --SetTextDropshadow(0, 0, 0, 0, 255)
    -- SetTextDropShadow()
    SetTextOutline(outline)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentString(text)
    EndTextCommandDisplayText( x + x_offset ,y + y_offset)
end

function DrawTime(time, type , x,y,size, r,g,b,alpha, font, right,width , center,outline)
    alpha = alpha or 255
    local x_offset , y_offset = 0 , 0
    if center == true then 
        SetTextJustification(0)
    end
    if right then
		SetTextWrap(x - width, x)
		SetTextRightJustify(true)
	end
    SetTextFont(font)
    SetTextScale(0.0, size)
    SetTextColour(r, g, b, alpha)
    --SetTextDropshadow(0, 0, 0, 0, 255)
    --SetTextDropShadow()
    SetTextOutline(outline)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringTime(time,type)
    EndTextCommandDisplayText( x + x_offset ,y + y_offset)
end


function DrawTimerBar(title, time, barIndex) 
	local width = 0.13
	local hTextMargin = 0.003
	local rectHeight = 0.038
	local textMargin = 0.008
	
	local rectX = GetSafeZoneSize() - width + width / 2
	local rectY = GetSafeZoneSize() - rectHeight + rectHeight / 2 - (barIndex - 1) * (rectHeight + 0.005)
	
	DrawSprite("timerbars", "all_black_bg", rectX, rectY, width, 0.038, 0, 0, 0, 0, 128)
	
	DrawText(title, GetSafeZoneSize() - width + hTextMargin, rectY - textMargin, 0.32,254, 254, 254, 255,0)
	
    DrawTime(time,7, GetSafeZoneSize() - ((width / 2) + hTextMargin * 3 ), rectY - 0.0175, 0.5, 254, 254, 254, 255,0, false, width)
    --DrawText(time, GetSafeZoneSize() - hTextMargin, rectY - 0.0175, 0.5, true, width / 2)
end

function DrawTextBar(title, text, barIndex) 
	local width = 0.13
	local hTextMargin = 0.003
	local rectHeight = 0.038
	local textMargin = 0.008
	
	local rectX = GetSafeZoneSize() - width + width / 2
	local rectY = GetSafeZoneSize() - rectHeight + rectHeight / 2 - (barIndex - 1) * (rectHeight + 0.005)
	
	DrawSprite("timerbars", "all_black_bg", rectX, rectY, width, 0.038, 0, 0, 0, 0, 128)
	
	DrawText(title, GetSafeZoneSize() - width + hTextMargin, rectY - textMargin, 0.32,254, 254, 254, 255,0)
	
    --DrawTime(time,7, GetSafeZoneSize() - hTextMargin, rectY - 0.0175, 0.5, 254, 254, 254, 255,0, true, width)
    DrawText(text,  GetSafeZoneSize() - hTextMargin, rectY - 0.0175, 0.5, 254, 254, 254, 255,0, true, width / 2)
end

function GetUserInput(windowTitle,defaultText,maxInputLength)
	
	maxInputLength = maxInputLength or 30

	local spacer = "\t";

	local title = windowTitle or "Enter"
	local title_entry = tostring(#title) .. tostring(math.random(1,1000)) .. '_WIN_TITLE'
	AddTextEntry(title_entry, title .. string.format('\t(Max %d characters)',maxInputLength))
	DisplayOnscreenKeyboard(1, title_entry, "", defaultText or "", "", "", "", maxInputLength);
	
	local result = nil

	while (UpdateOnscreenKeyboard() == 0) do
        DisableAllControlActions(0);
        Citizen.Wait(0);
    end
    if (GetOnscreenKeyboardResult()) then
        result = GetOnscreenKeyboardResult()
    end

	return result
end

function ShowNotification( message, color)
    if type(color) == 'string' then
        if color == 'red' then
            color = 6
        elseif color == 'green' then
            color = 184
        elseif color == 'yellow' then
            color = 190
        end
    end
    if color ~= nil then
        ThefeedSetNextPostBackgroundColor(color)
    end
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(true, true)
end