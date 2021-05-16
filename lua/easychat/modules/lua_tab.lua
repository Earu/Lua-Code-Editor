local NET_LUA_SEND_CODE = "EASY_CHAT_MODULE_LUA_SEND_CODE"

if SERVER then
	-- add luacheck to clients
	for _, file_name in ipairs(file.Find("lua/includes/modules/luacheck*", "GAME")) do
		AddCSLuaFile("includes/modules/" .. file_name)
	end

	AddCSLuaFile("lua_tab/panel.lua")
	AddCSLuaFile("lua_tab/luadev_compat.lua")
	include("lua_tab/luadev_compat.lua")

	util.AddNetworkString(NET_LUA_SEND_CODE)
	net.Receive(NET_LUA_SEND_CODE, function(_, ply)
		local url = net.ReadString()
		local target = net.ReadEntity()

		timer.Simple(0, function()
			net.Start(NET_LUA_SEND_CODE)
			net.WriteString(url)
			net.WriteEntity(ply)
			net.Send(target)
		end)
	end)
end

if CLIENT then
	include("lua_tab/panel.lua")

	local lua_tab = vgui.Create("ECLuaTab")
	EasyChat.AddTab("Lua", lua_tab, "icon16/page_edit.png")

	hook.Add("ECTabChanged", "EasyChatModuleLuaTab", function(_, new_tab_name)
		if new_tab_name ~= "Lua" then return end
		if not IsValid(lua_tab) then return end
		local active_code_tab = lua_tab.CodeTabs:GetActiveTab()
		if not IsValid(active_code_tab) then return end

		active_code_tab.m_pPanel:RequestFocus()
	end)

	net.Receive(NET_LUA_SEND_CODE, function()
		local url = net.ReadString()
		local sender = net.ReadEntity()
		if not IsValid(lua_tab) then return end

		local sender_nick = EasyChat.GetProperNick(sender)
		Derma_Query(("%s sent you code, open it?"):format(sender_nick), "Received Code", "Open", function()
			http.Fetch(url:gsub("pastebin.com/", "pastebin.com/raw/"), function(txt)
				if txt:match("%</html%>") then return end

				if EasyChat.Open() then
					EasyChat.OpenTab("Lua")
				end

				lua_tab:NewTab(txt)
			end, function()
				local err_msg = ("Could not load code from %s"):format(sender_nick)
				EasyChat.Print(true, err_msg)
				notification.AddLegacy(err_msg, NOTIFY_ERROR, 5)
				surface.PlaySound("buttons/button11.wav")
			end)
		end, "Dismiss", function() end)
	end)

	-- dont display it by default on small resolutions
	if not cookie.GetNumber("EasyChatSmallScreenLuaTab") and ScrW() < 1600 then
		local tab_data = EasyChat.GetTab("Lua")
		if tab_data and IsValid(tab_data.Tab) then
			tab_data.Tab:Hide()
		end

		cookie.Set("EasyChatSmallScreenLuaTab", "1")
	end

	hook.Add("ECFactoryReset", "EasyChatModuleLuaTab", function()
		cookie.Delete("EasyChatSmallScreenLuaTab")
		cookie.Delete("ECLuaTabTheme")
	end)

	lua_tab:LoadLastSession()

	local function save_hook()
		-- this can happen with disabled modules
		if not IsValid(lua_tab) then return end
		lua_tab:SaveSession()
	end

	hook.Add("ShutDown", "EasyChatModuleLuaTab", save_hook)
	hook.Add("ECPreDestroy", "EasyChatModuleLuaTab", save_hook)

	-- in case of crashes, have auto-saving
	timer.Create("EasyChatModuleLuaTabAutoSave", 300, 0, save_hook)
end

return "LuaTab"