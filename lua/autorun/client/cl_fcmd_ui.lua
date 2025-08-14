
include('cl_fcmd_core.lua')
local rootpath = 'fastcmd'
--------------------------------
local function CreateDialog(title, placeholder)
	local dialog = vgui.Create('DFrame')
	local w, h = ScrW(), ScrH()
	
	dialog:SetTitle(title)
	dialog:SetSize(250, 100)
	dialog:SetPos(w * 0.5 - 125, h * 0.5 - 50)
	dialog:SetDraggable(true)
	dialog:SetVisible(true)
	dialog:SetSizable(true)
	dialog:ShowCloseButton(true)
	dialog:SetDeleteOnClose(true)

	placeholder = placeholder or ''
	local textinput = vgui.Create('DTextEntry', dialog)
	textinput:SetPos(50, 30)
	textinput:SetSize(150, 20)
	textinput:SetPlaceholderText(placeholder)
	dialog.textinput = textinput
	function dialog:GetInput()
		return self.textinput:GetText()
	end


	local submitbtn = vgui.Create('DButton', dialog)
	submitbtn:SetPos(50, 60)
	submitbtn:SetSize(50, 20)
	submitbtn:SetText('#fcmd.ui.submit')
	submitbtn.DoClick = function() 
		if isfunction(dialog.SubmitCall) and dialog:SubmitCall() then
			dialog:Remove() 
		end
	end
	dialog.submitbtn = submitbtn


	local canclebtn = vgui.Create('DButton', dialog)
	canclebtn:SetPos(150, 60)
	canclebtn:SetSize(50, 20)
	canclebtn:SetText('#fcmd.ui.cancle')
    canclebtn.DoClick = function() dialog:Remove() end
	dialog.canclebtn = canclebtn

	dialog:MakePopup()
	dialog:SetKeyBoardInputEnabled(true)
    return dialog
end
--------------------------------
local FastCmdDataManager = {}
function FastCmdDataManager:Init()
	-- 数据列表
	local datalist = vgui.Create('DTree', self)
	self.datalist = datalist

	local title = vgui.Create('DLabel', self)
	title:SetColor(Color(0, 0, 0))
	self.title = title

	-- 编辑器按钮
	local editorbtn = vgui.Create('DButton', self)
	editorbtn:SetText('#fcmd.ui.editor')
	self.editorbtn = editorbtn

	-- 创建按钮
	local createbtn = vgui.Create('DButton', self)
	createbtn:SetText('#fcmd.ui.create')
	self.createbtn = createbtn

	-- 另存为按钮
	local saveasbtn = vgui.Create('DButton', self)
	saveasbtn:SetText('#fcmd.ui.saveas')
	saveasbtn.state = 0
	self.saveasbtn = saveasbtn

	-- 删除按钮
	local deletebtn = vgui.Create('DButton', self)
	deletebtn:SetText('#fcmd.ui.delete')
	deletebtn:SetTextColor(Color(255, 100, 50, 255))
	self.deletebtn = deletebtn


	self:SelectFile()
	self.saveAsState = 0

	-- 列表更新
	datalist.UpdateFileList = function() 
		notification.Kill('fcmd_update_filelist')
		datalist:Clear()

		local files = file.Find(rootpath..'/*.json', 'DATA')
		if #files < 1 then return end

		local activefile = GetConVar('cl_fcmd_file'):GetString()..'.json'
		for _, filename in pairs(files) do
			local icon 
			if filename == activefile then
				icon = 'icon16/tick.png'
			else
				icon = 'icon16/page.png'
			end

			local node = datalist:AddNode(filename, icon)	
			node.filename = filename
		end
	end

	-- 列表选择事件
	datalist.OnNodeSelected = function()
		-- 双击检查
		local filename = datalist:GetSelectedItem().filename
		if filename == self:GetSelectFile() and CurTime() - (datalist.clicktime or 0) < 0.3 then
			LocalPlayer():ConCommand('cl_fcmd_file 0')
			LocalPlayer():ConCommand('cl_fcmd_file '..string.sub(filename, 1, -6))
			self:UpdateFileList()
		end
		datalist.clicktime = CurTime()
		self:SelectFile(filename)
	end

	-- 编辑器按钮回调
	editorbtn.DoClick = function()
	end

	-- 创建按钮回调
	createbtn.DoClick = function()
		local dialog = CreateDialog('#fcmd.ui.title.name', '#fcmd.ui.placeholder.name')
		
		dialog.SubmitCall = function() 
			local filename = dialog:GetInput()
			return self:Create(filename) 
		end
	end

	-- 另存为按钮回调
	saveasbtn.DoClick = function()
		self.saveAsState = 0
		if self:GetSelectFile() == '' then
			fcmd_FastError('#fcmd.err.saveas', '#fcmd.err.unselect')
			return
		end

		local origin = string.sub(self:GetSelectFile(), 1, -6)
		local dialog = CreateDialog('#fcmd.ui.title.saveas', '#fcmd.ui.placeholder.name')
		dialog.SubmitCall = function()
			local target = dialog:GetInput()
			return self:SaveAs(origin, target)
		end
	end	

	-- 删除按钮回调
	deletebtn.DoClick = function()
		if self:GetSelectFile() == '' then
			fcmd_FastError('#fcmd.err.delete', '#fcmd.err.unselect')
			return
		end

		local filename = string.sub(self:GetSelectFile(), 1, -6)
		return self:Delete(filename)
	end
end

function FastCmdDataManager:SelectFile(filename)
	filename = isstring(filename) and filename or ''
	self.selectfile = filename
	self.title:SetText(language.GetPhrase('#fcmd.ui.select')..(filename == '' and 'None' or filename))
	self.saveAsState = 0
	self.deleteState = 0
end

function FastCmdDataManager:GetSelectFile()
	return isstring(self.selectfile) and self.selectfile or ''
end

function FastCmdDataManager:Create(filename)
	local succ = fcmd_CreateFcmdDataFile(filename)
	if succ then
		self:UpdateFileList()
		surface.PlaySound('garrysmod/ui_click.wav')
	end
	return succ
end

function FastCmdDataManager:SaveAs(origin, target)
	local state = self.saveAsState
	local progress = fcmd_SaveAsProgress(target, state == 0)
	
	if progress then
		state = state + progress
	else
		state = 0
	end
	self.saveAsState = state

	if state >= 2 then
		local succ = fcmd_SaveAs(origin, target)
		if succ then
			self:UpdateFileList()
			surface.PlaySound('garrysmod/ui_click.wav')
			state = 0
		end
		return succ
	end

	return false
end

function FastCmdDataManager:Delete(filename)
	self.deleteState = self.deleteState + 1
	if self.deleteState == 1 then
		fcmd_FastWarn('#fcmd.warn.delete')
		return false
	elseif self.deleteState >= 2 then
		self.deleteState = 0
		local succ = fcmd_Delete(filename)
		if succ then
			LocalPlayer():ConCommand('cl_fcmd_file 0')
			surface.PlaySound('Buttons.snd15')
			self:UpdateFileList()
		end
		return succ
	end
	return false
end

function FastCmdDataManager:UpdateFileList()
	self:SelectFile()
	timer.Simple(0.5, self.datalist.UpdateFileList)
	notification.AddProgress('fcmd_update_filelist', '#fcmd.ui.loading')
end

function FastCmdDataManager:OnSizeChanged(newWidth, newHeight)
	self.title:SetPos(0.1 * newWidth, 0)
	self.title:SetSize(0.8 * newWidth, 0.1 * newHeight)

	self.editorbtn:SetPos(0, 0.1 * newHeight)
	self.editorbtn:SetSize(newWidth, 0.08 * newHeight)

	self.datalist:SetPos(0, 0.2 * newHeight)
	self.datalist:SetSize(newWidth * 0.7, newHeight * 0.8)
	
	self.createbtn:SetPos(newWidth * 0.75, 0.2 * newHeight)
	self.createbtn:SetSize(newWidth * 0.25, 0.1 * newHeight)

	self.saveasbtn:SetPos(newWidth * 0.75, 0.32 * newHeight)
	self.saveasbtn:SetSize(newWidth * 0.25, 0.1 * newHeight)

	self.deletebtn:SetPos(newWidth * 0.75, 0.44 * newHeight)
	self.deletebtn:SetSize(newWidth * 0.25, 0.1 * newHeight)
end

vgui.Register('FastCmdDataManager', FastCmdDataManager, 'DPanel')
--------------------------------