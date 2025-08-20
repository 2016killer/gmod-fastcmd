include('ui/fcmd_wdatabrow.lua')
include('ui/fcmd_matbrow.lua')
include('ui/fcmd_soundbrow.lua')
include('ui/fcmd_editor.lua')
include('ui/fcmd_widget.lua')

concommand.Add('fcmd_version', function() print('1.0.0') end)

local convars = {
	cl_fcmd_wheel_size = 500,
	cl_fcmdm_expand_key = 0,
	cl_fcmd_call_key = 0,
	cl_fcmdm_break_key = 0,
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
		phrase('#fcmdu.menu.category'), 
		'fcmd_menu',
		phrase('#fcmdu.menu.name'), '', '', 
		function(panel)
			panel:Clear()

			-- 预设下拉框
			local ctrl = vgui.Create('ControlPresets', panel)
				ctrl:SetPreset('fcmd_menu')
				for k, v in pairs(convars) do ctrl:AddConVar(k) end
				ctrl:AddOption('#preset.default', convars)
				panel:AddPanel(ctrl)

			panel:NumSlider(phrase('#fcmdu.wheel_size'), 'cl_fcmd_wheel_size', 0, 1000, 0)

			-- 按键绑定
			panel:KeyBinder(
				phrase('#fcmdu.expand_key'), 
				'cl_fcmdm_expand_key', 
				phrase('#fcmdu.call_key'),
				'cl_fcmd_call_key'
			)
			panel:KeyBinder(
				phrase('#fcmdu.break_key'), 
				'cl_fcmdm_break_key'
			)


			panel:TextEntry(phrase('#fcmdu.wfile'), 'cl_fcmd_wfile')

			-- 轮盘数据浏览器
			local body = vgui.Create('DPanel', panel)
			local WheelDataBrowser = FcmduCreateWheelDataBrowser(body)
			body:SetHeight(250)
			panel:AddItem(body)
			
			cvars.AddChangeCallback('cl_fcmd_wfile', function(name, old, new) 
				WheelDataBrowser:Refresh()
			end, 'bbb')
			

			-- 编辑器按钮
			local EditorBtn = panel:Button(phrase('#fcmdu.editor'), '')
			EditorBtn.DoClick = function()
				if WheelDataBrowser.selectFile then
					LocalPlayer():ConCommand(string.format('fcmdu_open_editor "%s"', WheelDataBrowser.selectFile))
				else
					LocalPlayer():ConCommand(string.format('fcmdu_open_editor "%s"', GetConVar('cl_fcmd_wfile'):GetString()))
				end
			end

			panel:Button(phrase('#fcmdu.add_hook'), 'fcmd_add_hook')
			panel:CheckBox(phrase('#fcmdu.notify'), 'cl_fcmd_notify')
		end
	)
end)






