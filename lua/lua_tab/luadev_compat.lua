local NET_LUA_CLIENTS = "EASY_CHAT_MODULE_LUA_CLIENTS"
local NET_LUA_SV = "EASY_CHAT_MODULE_LUA_SV"

local lua = {}
if CLIENT then
	if _G.luadev then
		lua = _G.luadev
	else
		function lua.RunOnClient(code, target, _)
			if isentity(target) and target:IsPlayer() then
				net.Start(NET_LUA_SV)
				net.WriteString(code)
				net.WriteString("client")
				net.WriteEntity(target)
				net.SendToServer()
			end
		end

		function lua.RunOnClients(code, _)
			net.Start(NET_LUA_SV)
			net.WriteString(code)
			net.WriteString("clients")
			net.SendToServer()
		end

		function lua.RunOnSelf(code, _)
			net.Start(NET_LUA_SV)
			net.WriteString(code)
			net.WriteString("self")
			net.SendToServer()
		end

		function lua.RunOnShared(code, _)
			net.Start(NET_LUA_SV)
			net.WriteString(code)
			net.WriteString("shared")
			net.SendToServer()
		end

		function lua.RunOnServer(code, _)
			net.Start(NET_LUA_SV)
			net.WriteString(code)
			net.WriteString("server")
			net.SendToServer()
		end

		net.Receive(NET_LUA_CLIENTS, function()
			local code = net.ReadString()
			local ply = net.ReadEntity()
			if not IsValid(ply) then return end

			CompileString(code, ply:Nick())()
		end)
	end
end

if SERVER then
	util.AddNetworkString(NET_LUA_CLIENTS)
	util.AddNetworkString(NET_LUA_SV)

	local execution_callbacks = {
		["server"] = function(ply, code)
			CompileString(code, ply:Nick())()
		end,
		["client"] = function(ply, target, code)
			net.Start(NET_LUA_CLIENTS)
			net.WriteString(code)
			net.WriteEntity(ply)
			net.Send(target)
		end,
		["clients"] = function(ply, code)
			net.Start(NET_LUA_CLIENTS)
			net.WriteString(code)
			net.WriteEntity(ply)
			net.Broadcast()
		end,
		["shared"] = function(ply, code)
			CompileString(code, ply:Nick())()
			net.Start(NET_LUA_CLIENTS)
			net.WriteString(code)
			net.WriteEntity(ply)
			net.Broadcast()
		end,
		["self"] = function(ply, code)
			net.Start(NET_LUA_CLIENTS)
			net.WriteString(code)
			net.WriteEntity(ply)
			net.Send(ply)
		end
	}

	net.Receive(NET_LUA_SV, function(_, ply)
		if not IsValid(ply) then return end

		local code = net.ReadString()
		local mode = net.ReadString()
		if not ply:IsSuperAdmin() then return end

		local callback = execution_callbacks[mode]
		if callback then
			if mode == "client" then
				local target = net.ReadEntity()
				mode = tostring(target)
				callback(ply, target, code)
			else
				callback(ply, code)
			end

			EasyChat.Print(("%s running code on %s"):format(ply, mode))
		end
	end)
end

return lua