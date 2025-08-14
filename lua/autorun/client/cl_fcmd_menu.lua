

local convars = {
	cl_fcmd_menu_size = 500,
	cl_fcmd_expand_key = 0,
	cl_fcmd_execute_key = 0,
	cl_fcmd_break_key = 0,
	cl_fcmd_file = ''
}

for k, v in pairs(convars) do
	CreateClientConVar(k, tostring(v), true, false)
end

-------------------------
local phrase = language.GetPhrase


-------------------------菜单
local fcmddataManager
hook.Add('PopulateToolMenu', 'fcmd_menu', function()
	spawnmenu.AddToolMenuOption(
		'Utilities', 
		phrase('fcmd.menu.category'), 
		'fcmd_menu',
		phrase('fcmd.menu.name'), '', '', 
		function(panel)
			panel:Clear()

			-- 预设下拉框
			local ctrl = vgui.Create('ControlPresets', panel)
				ctrl:SetPreset('fcmd_menu')
				for k, v in pairs(convars) do ctrl:AddConVar(k) end
				ctrl:AddOption('#preset.default', convars)
				panel:AddPanel(ctrl)

			panel:NumSlider(phrase('fcmd.var.menu_size'), 'cl_fcmd_menu_size', 0, 1000, 0)

			-- 按键绑定
			panel:KeyBinder(
				phrase('fcmd.var.expand_key'), 
				'cl_fcmd_expand_key', 
				phrase('fcmd.var.execute_key'),
				'cl_fcmd_execute_key'
			)
			panel:KeyBinder(
				phrase('fcmd.var.break_key'), 
				'cl_fcmd_break_key'
			)

			fcmddataManager = vgui.Create('FastCmdDataManager', panel)
			fcmddataManager:SetHeight(250)
			fcmddataManager:UpdateFileList()
			panel:AddItem(fcmddataManager)
			
			panel:Button(phrase('fcmd.cmd.add_hook'), 'fcmd_add_hook')
		end
	)
end)

cvars.AddChangeCallback('cl_fcmd_file', function(name, old, new) 
	local newdata = fcmd_LoadFcmdDataFromFile(new)
	if istable(newdata) then surface.PlaySound('Weapon_AR2.Reload_Push') end
	fcmdm_SetCurrentFcmdData(newdata)
	fcmdm_SetCurrentCallData(nil)
	if IsValid(fcmddataManager) and fcmddataManager.UpdateFileList then
		fcmddataManager:UpdateFileList()
	end
end, 'aaa')







