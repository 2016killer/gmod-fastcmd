
local Background = Color(107, 110, 114, 200)


local example = [[
{
	"3dtransform": {
		"enable": true
	},
	"autoclip": true,
	"metadata": [
		{
			"call": {
				"pexecute": "test_example \"Hello World\""
			},
			"icon": "hud/fastcmd/world.jpeg"
		},
		{
			"call": {
				"pexecute": "test_example \"Hello Garry's Mod\""
			},
			"icon": "hud/fastcmd/gmod.jpeg"
		},
		{
			"call": {
				"pexecute": "test_example \"Hello Workshop\""
			},
			"icon": "hud/fastcmd/workshop.jpeg"
		}
	]
}
]]

function fcmdu_CreateFileList(panel)
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

	flist:UpdateFileList()
	return flist
end


local function CreateDialog()
	local dialog = vgui.Create('DFrame')
	local w, h = ScrW(), ScrH()
	
  
	dialog:SetTitle('')
	dialog:SetSize(250, 100)
	dialog:SetPos(w * 0.5 - 125, h * 0.5 - 50)
	dialog:SetDraggable(true)
	dialog:SetVisible(true)
	dialog:SetSizable(true)
	dialog:ShowCloseButton(true)
	dialog:SetDeleteOnClose(true)

	local textinput = vgui.Create('DTextEntry', dialog)
	textinput:SetPos(50, 30)
	textinput:SetSize(150, 20)
	dialog.textinput = textinput

	local submitbtn = vgui.Create('DButton', dialog)
	submitbtn:SetPos(50, 60)
	submitbtn:SetSize(50, 20)
	submitbtn:SetText('#fcmd.ui.submit')
	dialog.submitbtn = submitbtn


	local canclebtn = vgui.Create('DButton', dialog)
	canclebtn:SetPos(150, 60)
	canclebtn:SetSize(50, 20)
	canclebtn:SetText('#fcmd.ui.cancle')
    canclebtn.DoClick = function() dialog:Remove() end
	dialog.canclebtn = canclebtn

	local help = vgui.Create('DLabel', dialog)
	help:SetPos(210, 30)
	help:SetSize(500, 20)
	help:SetText('')
    help.Error = function(self, text)
        local errcolor = Color(255, 100, 50)
        self:SetColor(errcolor)
        self:SetText(text)
        dialog:SetWidth(300)
    end
	dialog.help = help

    return dialog
end

concommand.Add('fcmd_create', function()
    local root = 'fastcmd'
    local dialog = CreateDialog() 
    dialog:SetTitle('#fcmd.ui.title.name')
    dialog:MakePopup()
    dialog:SetKeyBoardInputEnabled(true)

    
    dialog.submitbtn.DoClick = function()
        -- 检查暂停
        if gui.IsGameUIVisible() then error('暂停时不可用') end

        -- 空名字
        local name = dialog.textinput:GetText() 
        if name == '' then
            dialog.help:Error('#fcmd.ui.err.name_empty')
            return
        end

        -- 检查重复
        name = name..'.json'
        if file.Exists(root..'/'..name, 'DATA') then
            dialog.help:Error('#fcmd.ui.err.name_exist')
        else
            file.Write(root..'/'..name, example)
            LocalPlayer():ConCommand('cl_fcmd_file 0')
            LocalPlayer():ConCommand('cl_fcmd_file '..name)
            dialog:Remove()
        end
    
    end
end)

concommand.Add('fcmd_delete', function(ply, cmd, args)
    local root = 'fastcmd'
    local filename = args[1]
	if filename == '' or filename == '0' or filename == 'empty' then
		// print('fcmd文件无效')
		return
	elseif filename:match('%.json$') == nil then
		error('必须是json格式')
	end

    sound.Play('Buttons.snd34', LocalPlayer():GetPos(), 75, 100)

	if filename == '' or filename == '0' or filename == 'empty' then
		// print('fcmd文件无效')
		return
	elseif filename:match('%.json$') == nil then
		error('必须是json格式')
	end

    file.Delete(root..'/'..filename, 'DATA')
end)