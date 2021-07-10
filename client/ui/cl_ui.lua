
-- finish MatchConfig

--[[

    [ Main Menu]
    - Create Match
        - Id 
        - Route
        - Name
        - Max Player
        - Max Laps
        - Create Btn
    - Join Match
    - Match List

]]


local MainMenu = RageUI.CreateMenu("Match Menu", "Race");
local CreateMatchMenu = RageUI.CreateSubMenu(MainMenu,"Create Match", "Race");
local MatchListMenu = RageUI.CreateSubMenu(MainMenu,"Match List", "Race");
local MatchConfig = RageUI.CreateSubMenu(MainMenu,"Match Config", "Race");


local MatchData = {
    name = 'race match',
    route_id = 'test3' ,
    id = 'race1',
    max_players = 2,
    max_laps = 1,
}
local ServerId = 0
function RageUI.PoolMenus:Main()
    MainMenu:IsVisible(function(Items)
        -- _match == nil
        if _match == nil then -- if player didn't in any match
            Items:AddButton("Create Match", "", { IsDisabled = false }, function(onSelected)    
            end, CreateMatchMenu)
            Items:AddButton("Join Match", " via id", { IsDisabled = false }, function(onSelected)    
            end)
            Items:AddButton("Match List", " matchlist ", { IsDisabled = false }, function(onSelected)    
                if onSelected then
                    sv_net_update('matchlist' , {'get'})
                end
            end, MatchListMenu)
            

        else
            Items:AddSeparator("Match Info")
            Items:AddButton("Name : " .. _match.name , "",  { IsDisabled = false } , function(onSelected)  end)
            Items:AddButton("Id : " .. _match.id, "", { IsDisabled = false } , function(onSelected)  end)
            Items:AddButton("Route : " .. _match.route.id,"",  { IsDisabled = false } , function(onSelected) end)
            
            Items:AddButton("Config","", { IsDisabled = false } , function(onSelected)  end, MatchConfig)
      

            -- Items:AddButton("Max Laps : " .. Match.max_laps, "", { IsDisabled = false } , function(onSelected)  end)

            Items:AddSeparator("PlayerList")
            
            for k , v in pairs(_match.playerlist) do
                local pl = GetPlayerFromServerId(v.id)
                --if v.id ~= ServerId then
                    local name = GetPlayerName(pl)
                    if v.ready == true then
                        name = '~g~' .. name
                    else
                        name = '~r~' .. name
                    end
                    Items:CheckBox(name, "", v.ready, {} , function()end)
                --end
                    
            end

            Items:AddSeparator("Option")
            Items:CheckBox("Ready", "", _match.ready , {} ,function(onSelected, IsChecked)
                if onSelected  then
                    _match:NetSetReady(IsChecked)
                end
            end)

            if _match.host == ServerId then
                Items:AddButton("~g~Start", "",  { IsDisabled = false } , function(onSelected) 
                    if onSelected then 
                        _match:NetStart()
                    end
                end)
            end

            Items:AddButton("~r~~h~Leave", "",  { IsDisabled = false } , function(onSelected) 
                if onSelected then 
                    _match:NetLeave()
                end
            end)
            
        end
    end , function(Items) end)


    MatchConfig:IsVisible(function(Items)
        Items:AddButton("Id : " .. _match.id, "", { IsDisabled = true } , function(onSelected)  end)
        Items:AddButton("Name : " .. _match.name , "",  { IsDisabled = false } , function(onSelected)  
            if onSelected then
                if _match.host == ServerId then 

                    local result = GetUserInput("Match Name")
                    if result ~= nil then
                        _match:NetSetName(result)
                    end

                end
            end
        end)

        
        Items:AddButton("Route : " .. _match.route.id ,"",  { IsDisabled = false } , function(onSelected) 
            if onSelected then
                if _match.host == ServerId then 
                
                    local result = GetUserInput("Match Route")
                    if result ~= nil then
                        _match:NetSetRouteById(result)
                    end

                end
            end
        end)

        Items:CheckBox("User Fninishline", "if set to false will use first checkpoint as finishline", MatchData.use_finishline , {} ,function(onSelected, IsChecked)
            if onSelected  then
                _match:NetSetUseFinishline(IsChecked)
            end
        end)

    end,function() end)

    CreateMatchMenu:IsVisible(function(Items)
        Items:AddButton("Set Name", "current match name : \"" .. MatchData.name .. '"', { IsDisabled = false }, function(onSelected) 
            if onSelected then
                local result = GetUserInput("Match Name")
                if result ~= nil then
                    MatchData.name = result
                end
            end
        end)
        Items:AddButton("Set Route", "current match Route : \"" .. MatchData.route_id .. '"', { IsDisabled = false }, function(onSelected) 
            if onSelected then
                local result = GetUserInput("Match Route")
                if result ~= nil then
                    MatchData.route_id = result
                end
            end
        end)
        Items:AddList("Set Max Player", { 1, 2, 3 , 4 , 5 }, MatchData.max_players, "current match max player : " .. MatchData.max_players, { IsDisabled = false }, function(Index, onSelected, onListChange)
			if (onListChange) then
				MatchData.max_players = Index;
			end
		end)

        Items:AddList("Set Max Laps", { 1, 2, 3 },  MatchData.max_laps, "current match max laps : " .. MatchData.max_laps, { IsDisabled = false }, function(Index, onSelected, onListChange)
			if (onListChange) then
				MatchData.max_laps = Index;
			end
		end)
        
        Items:CheckBox("User Fninishline", "if set to false will use first checkpoint as finishline", MatchData.use_finishline , {} ,function(onSelected, IsChecked)
            if onSelected  then
                MatchData.use_finishline = IsChecked
            end
        end)

        Items:AddButton("Create", 
            string.format( 
                'Name : %s \n'
                .. 'Route : %s \n'
                .. 'Max Players : %d \n'
                .. 'Max Laps : %d '
             , MatchData.name   , MatchData.route_id , MatchData.max_players ,  MatchData.max_laps) , { IsDisabled = false }, function(onSelected) 
            if onSelected then
                CMatch:NetCreate( MatchData.name , MatchData.password , MatchData.route_id , MatchData.use_finishline, MatchData.max_players , MatchData.max_laps)
                RageUI.GoBack()
            end
        end)


    end , function(Items) end)


    MatchListMenu:IsVisible(function(Items)
        for k ,v in pairs(_matchlist) do
            Items:AddButton(v.name, v.id , { IsDisabled = (v.password ~= nil) }, function(onSelected) 
                if onSelected then
                    CMatch:NetJoin(v.id)
                    RageUI.GoBack()
                end
            end)
        end
    end)

end


Keys.Register("E", "E", "Test", function()
	RageUI.Visible(MainMenu, not RageUI.Visible(MainMenu))
end)

Citizen.CreateThread(function()
    ServerId = GetPlayerServerId(GetPlayerIndex())
end)

_match  = nil
_matchlist = {}

AddEventHandler('pd_race:cl_net_update' , function(target , rawkeys , data)
    if target == 'error' then
        ShowNotification(string.format('~y~Error~w~: %s', data.msg or 'nil'))
        print('error : ',json.encode(rawkeys.keys),json.encode(data))
        return
    end
    local keys = CKeys:new(rawkeys)
    if target == 'match' and _match ~= nil then
        if _match:NetHandle(keys,data) == false then
            print('[Match:NetHandle(keys,data)]', target , json.encode(rawkeys) , json.encode(data))
        end
    elseif target == 'matchlist' then
        local action = keys:pop()
        if action == 'recive' then

            local prop = keys:pop()
            if prop == 'match' then
                _match = CMatch:new(data.value,true)
            elseif prop == 'matchlist' then
                _matchlist = data.value
            end
        elseif action == 'removed' then
            _match = nil 
            ShowNotification(string.format('~y~Removed from match ~w~: %s',data.reason or 'nil'))
        end
    end
end)