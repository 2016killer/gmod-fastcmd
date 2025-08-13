local convars = {
	cl_fcmd_menu_size = 500,
	cl_fcmd_expand_key = 0,
	cl_fcmd_execute_key = 0,
	cl_fcmd_break_key = 0,
}

for k, v in pairs(convars) do
	CreateClientConVar(k, tostring(v), true, false)
end

CreateClientConVar('cl_fcmd_menu_size', '500', true, false)

CreateClientConVar('cl_fcmd_expand_key', '0', true, false)
CreateClientConVar('cl_fcmd_execute_key', '0', true, false)
CreateClientConVar('cl_fcmd_break_key', '0', true, false)

if CLIENT then	
	local phrase = language.GetPhrase

	-- 菜单界面
	hook.Add('PopulateToolMenu', 'fastcmd', function()
		spawnmenu.AddToolMenuOption(
			'Utilities', 
			phrase('fcmd.menu.category'), 
			'fastcmd',
			phrase('fcmd.menu.name'), '', '', 
			function(panel)
				panel:Clear()

				-- 预设下拉框
				local ctrl = vgui.Create('ControlPresets', panel)
					ctrl:SetPreset('fastcmd')
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

				panel:Button(phrase('fcmd.cmd.open_editor'), '' )

				convars = nil
			end)
	end)

end




