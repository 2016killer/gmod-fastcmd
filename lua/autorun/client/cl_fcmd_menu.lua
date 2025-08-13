

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

local function CreateFileList(panel)
	local root = 'fastcmd'
	local flist = vgui.Create('DTree', panel)

	local function trim(str) 
		return str:gsub('^%s+', ''):gsub('%s+$', '') 
	end

	local function GetSelectFile()
		local filename, _ = trim(GetConVar('cl_fcmd_file'):GetString())
		if filename:match('%.json$') ~= nil then
			return filename
		else
			return ''
		end
	end

	flist.UpdateFileList = function(self)
		timer.Simple(0.5, function()
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
		end)
	end

	flist.OnNodeSelected = function(self)
		-- 双击检查
		if CurTime() - (self.clicktime or 0) < 0.3 then
			LocalPlayer():ConCommand('cl_fcmd_file 0')
			LocalPlayer():ConCommand('cl_fcmd_file '..self.selectfile)
			self:UpdateFileList()
		end
		self.clicktime = CurTime()
		self.selectfile = self:GetSelectedItem().filename
	end

	flist:SetHeight(250)
	flist:UpdateFileList()
	return flist
end

local example = [[
{
	"3dtransform": {
		"enable": true
	},
	"autoclip": true,
	"autoedge": true,
	"edgecolor": {
		"r": 255,
		"g": 255,
		"b": 255,
		"a": 255
	},

	"centersize": 0.5,
	"iconsize": 0.5,
	"fade": 100,
	"metadata": [
		{
			"call": {
				"pexecute": "fcmd_example Hello World",
				"rexecute": "",
				"sexecute": ""
			},
			"style": {
				"icon": "hud/fastcmd/world.jpeg"
			}
		},
		{
			"call": {
				"pexecute": "fcmd_example Hello Garry's Mod",
				"rexecute": "",
				"sexecute": ""
			},

			"style": {
				"icon": "hud/fastcmd/gmod.jpeg"
			}
		},
		{
			"call": {
				"pexecute": "fcmd_example Hello Workshop",
				"rexecute": "",
				"sexecute": ""
			},

			"style": {
				"icon": "hud/fastcmd/workshop.jpeg"
			}
		}
	]
}

]]


-------------------------菜单
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
			panel:AddItem(flist)

			panel:Button(phrase('fcmd.cmd.open_editor'), '')

			panel:Button(phrase('fcmd.cmd.new'), '')
			panel:Button(phrase('fcmd.cmd.saveas'), '')

			

			

			convars = nil
		end)
end)








