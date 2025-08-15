

local convars = {
	cl_fcmd_menu_size = 500,
	cl_fcmd_expand_key = 0,
	cl_fcmd_execute_key = 0,
	cl_fcmd_break_key = 0,
	cl_fcmd_wfile = 'fastcmd/wheel/chat.json',
	cl_fcmd_notify = 1
}

for k, v in pairs(convars) do
	CreateClientConVar(k, tostring(v), true, false)
end


local phrase = language.GetPhrase
-------------------------菜单
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

			// local body = vgui.Create('DPanel', panel)
			// body:SetHeight(250)
			// panel:AddItem(body)
			// CreateWheelDataBrowser(body)
			// fcmddataManager:UpdateFileList()
		
			// cvars.AddChangeCallback('cl_fcmd_wfile', function(name, old, new) 
			// 	fcmddataManager:UpdateFileList()
			// end, 'bbb')
			
			panel:Button(phrase('fcmd.cmd.add_hook'), 'fcmd_add_hook')
			panel:CheckBox(phrase('fcmd.var.notify'), 'cl_fcmd_notify')
		end
	)
end)








