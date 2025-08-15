
include('cl_fcmd_core.lua')
local rootpath = 'fastcmd'
local min = math.min
local max = math.max
local DrawHud2D = fcmd_DrawHud2D

local function SafeDrawHud2D(size, fcmddata, state, preview)
	local succ, err = pcall(DrawHud2D, size, fcmddata, state, preview)
	if not succ then
		ErrorNoHaltWithStack(err)
		fcmd_FastError('#fcmd.err.fatal', '#fcmd.err.data')

		render.ClearStencil()
		render.SetStencilEnable(false)
		render.OverrideColorWriteEnable(false)
		gui.EnableScreenClicker(false)
	end
	return succ
end

local background = Color(255, 255, 255, 200)
local function emptyfunc() end
--------------------------------
local function CreateDialog(title, placeholder)
	local dialog = vgui.Create('DFrame')

	dialog:SetTitle(title)
	dialog:SetSize(250, 100)
	dialog:Center()
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
local FcmdDataBrowser
local FcmdDataBaseFolder = 'data'

function OpenFcmdDataBrowser(parent)
	-- 数据列表
	if IsValid(FcmdDataBrowser) then FcmdDataBrowser:Remove() end

	FcmdDataBrowser = vgui.Create('DPanel', parent)
	FcmdDataBrowser:Dock(FILL)

	local SearchInput = vgui.Create('DTextEntry', FcmdDataBrowser)
	local RefreshBtn = vgui.Create('DButton', FcmdDataBrowser)

	
	// SearchInput:Dock(TOP)
	// RefreshBtn:Dock(LEFT)


	// local FileBrowser = vgui.Create('DFileBrowser', FcmdDataBrowser)
	// FileBrowser:Dock(FILL)
	// FileBrowser:SetPath('GAME') 
	// FileBrowser:SetBaseFolder('addons') 
	// FileBrowser:SetOpen(true) 

	// local title = vgui.Create('DLabel', self)
	// title:SetColor(Color(0, 0, 0))
	// self.title = title

	// -- 编辑器按钮
	// local editorbtn = vgui.Create('DButton', self)
	// editorbtn:SetText('#fcmd.ui.editor')
	// self.editorbtn = editorbtn

	// -- 创建按钮
	// local createbtn = vgui.Create('DButton', self)
	// createbtn:SetText('#fcmd.ui.create')
	// self.createbtn = createbtn

	// -- 另存为按钮
	// local saveasbtn = vgui.Create('DButton', self)
	// saveasbtn:SetText('#fcmd.ui.saveas')
	// saveasbtn.state = 0
	// self.saveasbtn = saveasbtn

	// -- 删除按钮
	// local deletebtn = vgui.Create('DButton', self)
	// deletebtn:SetText('#fcmd.ui.delete')
	// deletebtn:SetTextColor(Color(255, 100, 50, 255))
	// self.deletebtn = deletebtn

	// -- 预览按钮
	// local previewbtn = vgui.Create('DButton', self)
	// previewbtn:SetText('#fcmd.ui.enable_preview')
	// self.previewbtn = previewbtn


	// self:SelectFile()
	// self.saveAsState = 0

	// -- 列表更新
	// datalist.UpdateFileList = function() 
	// 	datalist:Clear()

	// 	local files = file.Find(rootpath..'/*.json', 'DATA')
	// 	if #files < 1 then return end

	// 	local activefile = GetConVar('cl_fcmd_file'):GetString()
	// 	for _, filename in pairs(files) do
	// 		filename = string.sub(filename, 1, -6)
	// 		local icon
	// 		if filename == activefile then
	// 			icon = 'icon16/tick.png'
	// 		elseif file.Exists('materials/fastcmd/thumbnail/'..filename..'.png', 'GAME') then
	// 			icon = 'fastcmd/thumbnail/'..filename..'.png'
	// 		else
	// 			icon = 'icon16/page.png'
	// 		end

	// 		local node = datalist:AddNode(filename, icon)	
	// 		node.filename = filename
	// 	end
	// end

	// -- 列表选择事件
	// datalist.OnNodeSelected = function()
	// 	-- 双击检查
	// 	local filename = datalist:GetSelectedItem().filename
	// 	if filename == self:GetSelectFile() and CurTime() - (datalist.clicktime or 0) < 0.3 then
	// 		self:DoubleSelect(filename)
	// 	end
	// 	datalist.clicktime = CurTime()
	// 	self:SelectFile(filename)
	// end

	// -- 编辑器按钮回调
	// editorbtn.DoClick = function()
	// end

	// -- 创建按钮回调
	// createbtn.DoClick = function()
	// 	local dialog = CreateDialog('#fcmd.ui.title.name', '#fcmd.ui.placeholder.name')
		
	// 	dialog.SubmitCall = function() 
	// 		local filename = dialog:GetInput()
	// 		return self:Create(filename) 
	// 	end
	// end

	// -- 另存为按钮回调
	// saveasbtn.DoClick = function()
	// 	self.saveAsState = 0
	// 	if self:GetSelectFile() == '' then
	// 		fcmd_FastError('#fcmd.err.saveas', '#fcmd.err.unselect')
	// 		return
	// 	end

	// 	local origin = self:GetSelectFile()
	// 	local dialog = CreateDialog('#fcmd.ui.title.saveas', '#fcmd.ui.placeholder.name')
	// 	dialog.SubmitCall = function()
	// 		local target = dialog:GetInput()
	// 		return self:SaveAs(origin, target)
	// 	end
	// end	

	// -- 删除按钮回调
	// deletebtn.DoClick = function()
	// 	if self:GetSelectFile() == '' then
	// 		fcmd_FastError('#fcmd.err.delete', '#fcmd.err.unselect')
	// 		return
	// 	end

	// 	return self:Delete(self:GetSelectFile())
	// end

	// -- 预览按钮回调
	// previewbtn.DoClick = function()
	// 	self.preview = !self.preview
	// 	if self.preview then
	// 		previewbtn:SetText('#fcmd.ui.disable_preview')
	// 		local filename = self:GetSelectFile()
	// 		if filename ~= '' then
	// 			self.fcmddata, _ = fcmd_LoadFcmdDataFromFile(filename)
	// 		end
	// 	else
	// 		previewbtn:SetText('#fcmd.ui.enable_preview')
	// 		self.fcmddata = nil
	// 	end
	// end

	FcmdDataBrowser:MakePopup()
	FcmdDataBrowser:SetKeyBoardInputEnabled(true)
end
local frame = vgui.Create('DFrame')
frame:SetSize(500, 500)
frame:Center()
frame:MakePopup()
frame:SetKeyBoardInputEnabled(true)
OpenFcmdDataBrowser(frame)


// --------------------------------
// local FastCmdDataManager = {}
// function FastCmdDataManager:Init()
// 	-- 数据列表
// 	local datalist = vgui.Create('DTree', self)
// 	self.datalist = datalist

// 	local title = vgui.Create('DLabel', self)
// 	title:SetColor(Color(0, 0, 0))
// 	self.title = title

// 	-- 编辑器按钮
// 	local editorbtn = vgui.Create('DButton', self)
// 	editorbtn:SetText('#fcmd.ui.editor')
// 	self.editorbtn = editorbtn

// 	-- 创建按钮
// 	local createbtn = vgui.Create('DButton', self)
// 	createbtn:SetText('#fcmd.ui.create')
// 	self.createbtn = createbtn

// 	-- 另存为按钮
// 	local saveasbtn = vgui.Create('DButton', self)
// 	saveasbtn:SetText('#fcmd.ui.saveas')
// 	saveasbtn.state = 0
// 	self.saveasbtn = saveasbtn

// 	-- 删除按钮
// 	local deletebtn = vgui.Create('DButton', self)
// 	deletebtn:SetText('#fcmd.ui.delete')
// 	deletebtn:SetTextColor(Color(255, 100, 50, 255))
// 	self.deletebtn = deletebtn

// 	-- 预览按钮
// 	local previewbtn = vgui.Create('DButton', self)
// 	previewbtn:SetText('#fcmd.ui.enable_preview')
// 	self.previewbtn = previewbtn


// 	self:SelectFile()
// 	self.saveAsState = 0

// 	-- 列表更新
// 	datalist.UpdateFileList = function() 
// 		datalist:Clear()

// 		local files = file.Find(rootpath..'/*.json', 'DATA')
// 		if #files < 1 then return end

// 		local activefile = GetConVar('cl_fcmd_file'):GetString()
// 		for _, filename in pairs(files) do
// 			filename = string.sub(filename, 1, -6)
// 			local icon
// 			if filename == activefile then
// 				icon = 'icon16/tick.png'
// 			elseif file.Exists('materials/fastcmd/thumbnail/'..filename..'.png', 'GAME') then
// 				icon = 'fastcmd/thumbnail/'..filename..'.png'
// 			else
// 				icon = 'icon16/page.png'
// 			end

// 			local node = datalist:AddNode(filename, icon)	
// 			node.filename = filename
// 		end
// 	end

// 	-- 列表选择事件
// 	datalist.OnNodeSelected = function()
// 		-- 双击检查
// 		local filename = datalist:GetSelectedItem().filename
// 		if filename == self:GetSelectFile() and CurTime() - (datalist.clicktime or 0) < 0.3 then
// 			self:DoubleSelect(filename)
// 		end
// 		datalist.clicktime = CurTime()
// 		self:SelectFile(filename)
// 	end

// 	-- 编辑器按钮回调
// 	editorbtn.DoClick = function()
// 	end

// 	-- 创建按钮回调
// 	createbtn.DoClick = function()
// 		local dialog = CreateDialog('#fcmd.ui.title.name', '#fcmd.ui.placeholder.name')
		
// 		dialog.SubmitCall = function() 
// 			local filename = dialog:GetInput()
// 			return self:Create(filename) 
// 		end
// 	end

// 	-- 另存为按钮回调
// 	saveasbtn.DoClick = function()
// 		self.saveAsState = 0
// 		if self:GetSelectFile() == '' then
// 			fcmd_FastError('#fcmd.err.saveas', '#fcmd.err.unselect')
// 			return
// 		end

// 		local origin = self:GetSelectFile()
// 		local dialog = CreateDialog('#fcmd.ui.title.saveas', '#fcmd.ui.placeholder.name')
// 		dialog.SubmitCall = function()
// 			local target = dialog:GetInput()
// 			return self:SaveAs(origin, target)
// 		end
// 	end	

// 	-- 删除按钮回调
// 	deletebtn.DoClick = function()
// 		if self:GetSelectFile() == '' then
// 			fcmd_FastError('#fcmd.err.delete', '#fcmd.err.unselect')
// 			return
// 		end

// 		return self:Delete(self:GetSelectFile())
// 	end

// 	-- 预览按钮回调
// 	previewbtn.DoClick = function()
// 		self.preview = !self.preview
// 		if self.preview then
// 			previewbtn:SetText('#fcmd.ui.disable_preview')
// 			local filename = self:GetSelectFile()
// 			if filename ~= '' then
// 				self.fcmddata, _ = fcmd_LoadFcmdDataFromFile(filename)
// 			end
// 		else
// 			previewbtn:SetText('#fcmd.ui.enable_preview')
// 			self.fcmddata = nil
// 		end
// 	end
// end

// function FastCmdDataManager:SelectFile(filename)
// 	filename = isstring(filename) and filename or ''
// 	self.selectfile = filename
// 	self.title:SetText(language.GetPhrase('#fcmd.ui.select')..(filename == '' and 'None' or filename))
// 	self.saveAsState = 0
// 	self.deleteState = 0
// 	if self.preview then
// 		self.fcmddata, _ = fcmd_LoadFcmdDataFromFile(filename)
// 	end
// end

// function FastCmdDataManager:GetSelectFile()
// 	return isstring(self.selectfile) and self.selectfile or ''
// end

// function FastCmdDataManager:DoubleSelect(filename)
// 	fcmdm_LoadCurrentFcmdData(filename)
// 	self:UpdateFileList()
// end

// function FastCmdDataManager:Create(filename)
// 	local succ = fcmd_CreateFcmdDataFile(filename)
// 	if succ then
// 		self:UpdateFileList()
// 		surface.PlaySound('garrysmod/ui_click.wav')
// 	end
// 	return succ
// end

// function FastCmdDataManager:SaveAs(origin, target)
// 	local state = self.saveAsState
// 	local progress, _ = fcmd_SaveAsProgress(target, state == 0)
	
// 	if progress then
// 		state = state + progress
// 	else
// 		state = 0
// 	end
// 	self.saveAsState = state

// 	if state >= 2 then
// 		local succ, _ = fcmd_SaveAs(origin, target)
// 		if succ then
// 			self:UpdateFileList()
// 			surface.PlaySound('garrysmod/ui_click.wav')
// 			state = 0
// 		end
// 		return succ
// 	end

// 	return false
// end

// function FastCmdDataManager:Delete(filename)
// 	self.deleteState = self.deleteState + 1
// 	if self.deleteState == 1 then
// 		fcmd_FastWarn('#fcmd.warn.delete')
// 		return false
// 	elseif self.deleteState >= 2 then
// 		self.deleteState = 0
// 		local succ, _ = fcmd_Delete(filename)
// 		if succ then
// 			LocalPlayer():ConCommand('cl_fcmd_file 0')
// 			surface.PlaySound('Buttons.snd15')
// 			self:UpdateFileList()
// 		end
// 		return succ
// 	end
// 	return false
// end

// function FastCmdDataManager:UpdateFileList()
// 	self:SelectFile()
// 	timer.Simple(0.5, self.datalist.UpdateFileList)
// 	fcmd_FastProgress('#fcmd.ui.loading')
// end

// function FastCmdDataManager:OnSizeChanged(newWidth, newHeight)
// 	self.title:SetPos(0.1 * newWidth, 0)
// 	self.title:SetSize(0.8 * newWidth, 0.1 * newHeight)

// 	self.editorbtn:SetPos(0, 0.1 * newHeight)
// 	self.editorbtn:SetSize(newWidth, 0.08 * newHeight)

// 	self.datalist:SetPos(0, 0.2 * newHeight)
// 	self.datalist:SetSize(newWidth * 0.7, newHeight * 0.8)
	
// 	self.createbtn:SetPos(newWidth * 0.75, 0.2 * newHeight)
// 	self.createbtn:SetSize(newWidth * 0.25, 0.1 * newHeight)

// 	self.saveasbtn:SetPos(newWidth * 0.75, 0.32 * newHeight)
// 	self.saveasbtn:SetSize(newWidth * 0.25, 0.1 * newHeight)

// 	self.deletebtn:SetPos(newWidth * 0.75, 0.44 * newHeight)
// 	self.deletebtn:SetSize(newWidth * 0.25, 0.1 * newHeight)

// 	self.previewbtn:SetPos(newWidth * 0.75, 0.56 * newHeight)
// 	self.previewbtn:SetSize(newWidth * 0.25, 0.1 * newHeight)

// 	self.previewtrans = {
// 		x = newWidth * 0.75,
// 		y = newHeight * 0.7,
// 		w = newWidth * 0.25,
// 		h = newWidth * 0.25,
// 	}
// end

// function FastCmdDataManager:Paint(w, h)
// 	self.BaseClass.Paint(self, w, h)
// 	if self.preview and istable(self.fcmddata) then
// 		local succ = SafeDrawHud2D(
// 			w * 0.15, 
// 			self.fcmddata, 
// 			1, 
// 			self.previewtrans
// 		)
// 		if not succ then self.fcmddata = nil end
// 	end
// end

// PrintTable(engine.GetAddons())
// local addonMat = AddonMaterial('workshop/16201075788426353854.cache')
// print(addonMat)

// vgui.Register('FastCmdDataManager', FastCmdDataManager, 'DPanel')
