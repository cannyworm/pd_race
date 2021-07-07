

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

local MatchData = {
    name = 'race match',
    route_id = 'test3' ,
    id = 'race1',
    max_players = 5,
    max_laps = 1,
}

function RageUI.PoolMenus:Main()
    MainMenu:IsVisible(function(Items)

        if Match == nil then -- if player didn't in any match
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
            Items:AddButton("Name : " .. Match.name , "",  { IsDisabled = false } , function(onSelected)  end)
            Items:AddButton("Id : " .. Match.id, "", { IsDisabled = false } , function(onSelected)  end)
            Items:AddButton("Route : " .. Match.route.id,"",  { IsDisabled = false } , function(onSelected)  end)
            -- Items:AddButton("Max Laps : " .. Match.max_laps, "", { IsDisabled = false } , function(onSelected)  end)

            Items:AddSeparator("PlayerList")
            
            for k , v in pairs(Match.playerlist) do
                local pl = GetPlayerFromServerId(v.id)
                if v.id ~= GetPlayerServerId(GetPlayerIndex()) then
                    local name = GetPlayerName(pl)
                    if v.ready == true then
                        name = '~g~' .. name
                    else
                        name = '~r~' .. name
                    end
                    Items:CheckBox(name, "", v.ready, {} , function()end)
                end
                    
            end

            Items:AddSeparator("Option")
            Items:CheckBox("Ready", "", Match.ready , {} ,function(onSelected, IsChecked)
                if onSelected  then
                    Match:SetReady(IsChecked)
                end
            end)

            Items:AddButton("~g~Start", "",  { IsDisabled = false } , function(onSelected) 
                if onSelected then 
                    Match:Start()
                end
             end)
            Items:AddButton("~r~~h~Leave", "",  { IsDisabled = false } , function(onSelected) 
                if onSelected then 
                    Match:NetLeave()
                end
            end)
            
        end
    end , function(Items) end)


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
        Items:AddButton("Set Id", "current match Id : \"" .. MatchData.id .. '"', { IsDisabled = false }, function(onSelected) 
            if onSelected then
                local result = GetUserInput("Match Id")
                if result ~= nil then
                    MatchData.id = result
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
                .. 'Id : %s \n'
                .. 'Route : %s \n'
                .. 'Max Players : %d \n'
                .. 'Max Laps : %d '
             , MatchData.name  , MatchData.id , MatchData.route_id , MatchData.max_players ,  MatchData.max_laps) , { IsDisabled = false }, function(onSelected) 
            if onSelected then
                CMatch:NetCreate(MatchData.id , MatchData.name , MatchData.password , MatchData.route_id , MatchData.use_finishline, MatchData.max_players , MatchData.max_laps)
                RageUI.GoBack()
            end
        end)

        



    end , function(Items) end)


    MatchListMenu:IsVisible(function(Items)
        for k ,v in pairs(Matchlist) do
            Items:AddButton(v.name, v.id , { IsDisabled = (v.password ~= nil) }, function(onSelected) 
                if onSelected then
                    CMatch:NetJoin(v.id)
                end
            end)
        end
    end)


end


Keys.Register("E", "E", "Test", function()
	RageUI.Visible(MainMenu, not RageUI.Visible(MainMenu))
end)

Citizen.CreateThread(function()
    Callbacks:add_callback( 'matchrecv_fns' , function(match)
        if match.error == true then
            ShowNotification('~r~ Error ~w~: ' .. match.reason)
        end
    end)
end)