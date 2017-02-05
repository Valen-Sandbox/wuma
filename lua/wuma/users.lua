
WUMA = WUMA or {}
WUMA.Users = {}

WUMA.HasUserAccessNetworkBool = "WUMAHasAccess"

function WUMA.InitializeUser(user)
	WUMA.AssignRestrictions(user)
	WUMA.AssignLimits(user)
	WUMA.AssignLoadout(user)
	
	WUMA.AssignUserRegulations(user)
	
	if user:HasWUMAData() then
		WUMA.AddLookup(user)
	end
	
	WUMA.HasAccess(user, function(bool) 
		user:SetNWBool( WUMA.HasUserAccessNetworkBool, bool )
	end)	
	
end

function WUMA.AssignUserRegulations(user)
	WUMA.AssignUserRestrictions(user)
	WUMA.AssignUserLimits(user)
	WUMA.AssignUserLoadout(user)
end

function WUMA.AssignUserRestrictions(user)
	if WUMA.CheckUserFileExists(user,Restriction) then
		local tbl = WUMA.GetSavedRestrictions(user)
		for _,obj in pairs(tbl) do
			user:AddRestriction(obj)
		end
	end
end

function WUMA.AssignUserLimits(user)
	if WUMA.CheckUserFileExists(user,Limit) then
		local tbl = WUMA.GetSavedLimits(user)
		for _,obj in pairs(tbl) do
			user:AddLimit(obj)
		end
	end
end

function WUMA.AssignUserLoadout(user)
	if WUMA.HasPersonalLoadout(user) then
		local tbl = WUMA.GetSavedLoadout(user)
		user:SetLoadout(tbl)
	end
end

function WUMA.UpdateUsergroup(group,func)
	local players = WUMA.GetUsers(group)
	if not players then return false end
	for _,user in pairs(players) do
		func(user)
	end
	return players
end

function WUMA.GetUserData(user,typ)
	if not isstring(user) then user = user:SteamID() end
	
	if not WUMA.IsSteamID(user) then return false end

	local restrictions = false
	local limits = false
	local loadout = false
	
	if typ then
		if (typ == Restriction:GetID() and WUMA.CheckUserFileExists(user,Restriction)) then
			return WUMA.ReadUserRestrictions(user)
		elseif (typ == Limit:GetID() and WUMA.CheckUserFileExists(user,Limit)) then 
			return WUMA.ReadUserLimits(user)
		elseif (typ == Loadout:GetID() and WUMA.CheckUserFileExists(user,Loadout)) then 
			return WUMA.ReadUserLoadout(user)
		else
			return false
		end
	end
	
	if WUMA.CheckUserFileExists(user,Restriction) then restrictions = WUMA.ReadUserRestrictions(user) end
	if WUMA.CheckUserFileExists(user,Limit) then limits = WUMA.ReadUserLimits(user) end
	if WUMA.CheckUserFileExists(user,Loadout) then loadout = WUMA.ReadUserLoadout(user) end

	if not restrictions and not limits and not loadout then return false end
		
	return {
		steamid = user,
		restrictions = restrictions,
		limits = limits,
		loadout = loadout
	}
end

function WUMA.GetUsers(group)
	if not group then return player.GetAll() end	

	--Check for normal usergroup
	if isstring(group) then
		local tbl = {}
		for _,ply in pairs(player.GetAll()) do 
			if (string.lower(ply:GetUserGroup()) == string.lower(group)) then 
				table.insert(tbl,ply) 
			end
		end
		return tbl
	end
	
end

function WUMA.GetAuthorizedUsers(callback)
	CAMI.GetPlayersWithAccess(WUMA.WUMAGUI, callback)
end

function WUMA.HasAccess(user,callback)
	CAMI.PlayerHasAccess(user, WUMA.WUMAGUI, callback)
end

function WUMA.UserToTable(user)
	if (string.lower(type(user)) == "table") then
		return user
	else
		return {user}
	end
end

function WUMA.IsSteamID(steamid)
	if not isstring(steamid) then return false end
	return string.match(steamid,[[STEAM_\d{1}:\d{1}:\d*]])
end

function WUMA.GetUserGroups()
	local groups = {"superadmin","admin","user"}
	for group, tbl in pairs(CAMI.GetUsergroups()) do
		if not table.HasValue(groups,group) then table.insert(groups,group) end
	end
	return groups
end

function WUMA.UserDisconnect(user)
	if user:HasWUMAData() then
		WUMA.AddLookup(user)
	end
end
hook.Add("PlayerDisconnected", "WUMAPlayerDisconnected", WUMA.UserDisconnect, 0)

function WUMA.PlayerLoadout(user)
	return user:GiveLoadout()
end
hook.Add("PlayerLoadout", "WUMAPlayerLoadout", WUMA.PlayerLoadout, -1)

function WUMA.PlayerInitialSpawn(user)
	WUMA.InitializeUser(user) 
	timer.Simple(1,function() WUMA.GetAuthorizedUsers(function(users) WUMA.NET.USERS:Send(users) end) end)
end
hook.Add("PlayerInitialSpawn", "WUMAPlayerInitialSpawn", WUMA.PlayerInitialSpawn, -2)

function WUMA.PlayerUsergroupChanged(user, old, new, source)
	WUMA.RefreshGroupRestrictions(user,new)
	WUMA.RefreshGroupLimits(user,new)
	WUMA.RefreshLoadout(user,new)
	
	timer.Simple(2, function()
		WUMA.HasAccess(user, function(bool) 
			user:SetNWBool( WUMA.HasUserAccessNetworkBool, bool )
			user:SendLua([[WUMA.RequestFromServer(WUMA.NET.SETTINGS:GetID())]])
		end)
	end)	
end
hook.Add("CAMI.PlayerUsergroupChanged", "WUMAPlayerUsergroupChanged", WUMA.PlayerUsergroupChanged)
