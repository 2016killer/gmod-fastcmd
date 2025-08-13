include('cl_fcmd_main.lua')

local phrase = language.GetPhrase

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
CreateClientConVar('cl_fcmd_file', '', true, false)
-------------------------
local root = 'fastcmd'

cvars.AddChangeCallback('cl_fcmd_file', function(name, old, new)
	local json = file.Read(root..'/'..new, 'DATA')	

	local succ, err = pcall(function()
		fcmdm_SetCurrentFcmdData(fcmd_LoadsFcmdData(json))
	end)

	if succ then
		LocalPlayer():EmitSound('Buttons.snd34', 75, 100)	
	else
		LocalPlayer():EmitSound('Buttons.snd10', 75, 100)
		print('fcmd: '..json..'\n')
		Error('err: '..err..'\n')
	end
end)



local function CreateFileList(panel)
	
	local flist = vgui.Create('DTree', panel)

	local function trim(str) 
		return str:gsub('^%s+', ''):gsub('%s+$', '') 
	end

	local function GetSelectFile()
		local file, _ = trim(GetConVar('cl_fcmd_file'):GetString())
		if file:match('%.json$') ~= nil then
			return file
		else
			return ''
		end
	end

	flist.UpdateFileList = function(self)
		self:Clear()
		local files = file.Find(root..'/*.json', 'DATA')
		if #files < 1 then return end
		local selectfile = GetSelectFile()
		for _, filename in pairs(files) do
			local icon 
			if filename == selectfile then
				icon = 'icon16/tick.png'
			else
				icon = 'icon16/page.png'
			end

			local node = self:AddNode(filename, icon)	
			node.filename = filename
		end
	end

	flist.OnNodeSelected = function(self)
		-- 双击检查
		if CurTime() - self.clicktime < 0.3 then
			
			if data then
				LocalPlayer():EmitSound('Buttons.snd34', 75, 100)	
				LocalPlayer():ConCommand('cl_fcmd_file '..self.selectfile)
			else
				LocalPlayer():EmitSound('Buttons.snd10', 75, 100)
				LocalPlayer():ConCommand('cl_fcmd_file empty')		
			end
			self:UpdateFileList()
		end
		self.clicktime = CurTime()
		self.selectfile = self:GetSelectedItem().filename
	end

	flist:SetHeight(250)
	panel:AddItem(flist)
	flist:UpdateFileList()
	return flist
end

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

			local filelist = CreateFileList(panel)


			panel:Button(phrase('fcmd.cmd.open_editor'), '' )

			convars = nil
		end)
end)










