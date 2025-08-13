
include('cl_fcmd_core.lua')
local rootpath = 'fastcmd'
local FastError = fcmd_FastError
local FastWarning = fcmd_FastWarning


function fcmdu_CreateFileList(panel)
	
	local flist = vgui.Create('DTree', panel)

	flist.UpdateFileList = function(self)
		timer.Simple(0.5, function()
			self:Clear()

			local files = file.Find(rootpath..'/*.json', 'DATA')
			if #files < 1 then return end

			local selectfile = GetConVar('cl_fcmd_file'):GetString()..'.json'
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
		self.selectfile = string.sub(self:GetSelectedItem().filename, 1, -6)
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

    return dialog
end

concommand.Add('fcmd_create', function()
    local dialog = CreateDialog() 
    dialog:SetTitle('#fcmd.ui.title.name')
    dialog:MakePopup()
    dialog:SetKeyBoardInputEnabled(true)

    dialog.submitbtn.DoClick = function()
		local filename = dialog.textinput:GetText()
		local succ = fcmd_CreateFcmdDataFile(filename)
		if succ then
			LocalPlayer():ConCommand('cl_fcmd_file 0')
            LocalPlayer():ConCommand('cl_fcmd_file '..filename)
			dialog:Remove()
		end
    end
end)

concommand.Add('fcmd_delete', function(ply, cmd, args)
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

    file.Delete(rootpath..'/'..filename, 'DATA')
end)