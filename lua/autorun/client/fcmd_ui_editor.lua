
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
local FcmdDataBaseFolder = 'data/fastcmd/wheel'

function OpenFcmdDataBrowser(parent)
	-- 数据列表
	if IsValid(FcmdDataBrowser) then FcmdDataBrowser:Remove() end
	FcmdDataBrowser = vgui.Create('DFrame', parent)

	local SearchInput = vgui.Create('DTextEntry', FcmdDataBrowser)
	SearchInput:Dock(TOP)

	local RefreshBtn = vgui.Create('DButton', FcmdDataBrowser)
	RefreshBtn:Dock(LEFT)


	// local FileBrowser = vgui.Create('DFileBrowser', FcmdDataBrowser)
	// FileBrowser:Dock(FILL)
	// FileBrowser:SetPath('GAME') 
	// FileBrowser:SetBaseFolder('sound') 
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
OpenFcmdDataBrowser(Frame)

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
// --------------------------------
// MaterialsBrowser = nil
// local function OpenMaterialsBrowser()
// 	if IsValid(MaterialsBrowser) then MaterialsBrowser:Remove() end
// 	local scrw, scrh = ScrW(), ScrH()

// 	MaterialsBrowser = vgui.Create('DFrame')
// 	MaterialsBrowser:SetTitle('#fcmd.ui.title.material_browser')
// 	MaterialsBrowser:SetSize(scrw * 0.5, scrh * 0.5)
// 	MaterialsBrowser:Center()
// 	MaterialsBrowser:SetSizable(true)
// 	MaterialsBrowser:MakePopup()
// 	MaterialsBrowser:SetDeleteOnClose(true)
// 	MaterialsBrowser:SetMinimumSize(120 , 100)

// 	local tabs = vgui.Create('DPropertySheet', MaterialsBrowser)
// 	local submitbtn = vgui.Create('DButton', MaterialsBrowser)

// 	submitbtn:SetText('#fcmd.ui.submit')
// 	tabs:Dock(FILL)
// 	submitbtn:Dock(BOTTOM)
// 	----
// 	local addonMatBrowser = vgui.Create('DPanel', MaterialsBrowser)
// 	local addonMatBrowserDiv = vgui.Create('DHorizontalDivider', addonMatBrowser)
// 	local addonViewPort = vgui.Create('DPanel', addonMatBrowser)
// 	local addonSelectPanel = vgui.Create('DPanel', addonMatBrowser)

// 	local addonSearch = vgui.Create('DTextEntry', addonSelectPanel)
// 	local addonTree = vgui.Create('DTree', addonSelectPanel)
// 	local addonMat
	
// 	tabs:AddSheet('#fcmd.ui.title.addon', addonMatBrowser, 'icon16/bricks.png', false, false, '')
// 	addonMatBrowser.Paint = emptyfunc

// 	addonMatBrowserDiv:Dock(FILL)
// 	addonMatBrowserDiv:SetLeft(addonSelectPanel)
// 	addonMatBrowserDiv:SetRight(addonViewPort)
// 	addonMatBrowserDiv:SetDividerWidth(4)
// 	addonMatBrowserDiv:SetLeftMin(20) 
// 	addonMatBrowserDiv:SetRightMin(20)
// 	addonMatBrowserDiv:SetLeftWidth(scrw * 0.5 * 0.7)

// 	function addonViewPort:Paint(w, h)
// 		draw.RoundedBox(5, 0, 0, w, h, background)
// 		if addonMat then
// 			local matWidth = min(w, h)
// 			local cx, cy = (w - matWidth) * 0.5, (h - matWidth) * 0.5
// 			surface.SetDrawColor(255, 255, 255, 255)
// 			surface.SetMaterial(addonMat)
// 			surface.DrawTexturedRect(cx, cy, matWidth, matWidth)
// 		end
// 	end

// 	addonSearch:Dock(TOP)
// 	addonTree:Dock(FILL)

// 	for _, addon in ipairs(engine.GetAddons()) do 
// 		local file_ = addon.file
// 		if file ~= '' then
// 			local node = addonTree:AddNode(addon.title or '', 'icon16/page.png')
// 			node.file = file_	
// 		end
// 	end

// 	function addonTree:OnNodeSelected()
// 		// local addonMat = AddonMaterial('895632296.gma')
// 	end
// 	----
// 	local gameMatBrowser = vgui.Create('DPanel', MaterialsBrowser)
// 	local gameViewPort = vgui.Create('DPanel', gameMatBrowser)
// 	local gameMatFileBrowser = vgui.Create('DFileBrowser', gameMatBrowser)
// 	local div = vgui.Create('DHorizontalDivider', gameMatBrowser)
// 	local gamemat

// 	tabs:AddSheet('#fcmd.ui.title.game', gameMatBrowser, 'materials/icon16/add.png', false, false, '')
// 	gameMatBrowser.Paint = emptyfunc

// 	div:Dock(FILL)
// 	div:SetLeft(gameMatFileBrowser)
// 	div:SetRight(gameViewPort)
// 	div:SetDividerWidth(4)
// 	div:SetLeftMin(20) 
// 	div:SetRightMin(20)
// 	div:SetLeftWidth(scrw * 0.5 * 0.7)


// 	gameMatFileBrowser:SetPath('GAME') 
// 	gameMatFileBrowser:SetBaseFolder('materials') 
// 	gameMatFileBrowser:SetOpen(true) 

// 	function gameViewPort:Paint(w, h)
// 		draw.RoundedBox(5, 0, 0, w, h, background)
// 		if selectmaterial then
// 			local matWidth = min(w, h)
// 			local cx, cy = (w - matWidth) * 0.5, (h - matWidth) * 0.5
// 			surface.SetDrawColor(255, 255, 255, 255)
// 			surface.SetMaterial(selectmaterial)
// 			surface.DrawTexturedRect(cx, cy, matWidth, matWidth)
// 		end
// 	end

// 	function gameMatFileBrowser:OnSelect(path, pnl) 
// 		selectmaterial = Material(string.sub(path, 11, -1))
// 	end

// 	function gameMatFileBrowser:OnRightClick(filePath, selectedPanel) 
// 		local menu = DermaMenu() 
// 		menu:AddOption('#fcmd.ui.copy', function() SetClipboardText(filePath) end)
// 		menu:AddOption('#fcmd.ui.apply', function()  end)
		
// 		menu:Open()
// 	end

// end

// SoundBrowser = nil
// local function OpenSoundBrowser()
// 	if IsValid(SoundBrowser) then SoundBrowser:Remove() end

// 	SoundBrowser = vgui.Create('DFrame')
// 	SoundBrowser:SetTitle('#fcmd.ui.title.sound_browser')
// 	SoundBrowser:SetPos(x or 0, y or 0)
// 	SoundBrowser:SetSize(w or 500, h or 500)
// 	SoundBrowser:SetSizable(true)
// 	SoundBrowser:MakePopup()
// 	SoundBrowser:SetDeleteOnClose(true)
// 	SoundBrowser.soundobj = nil
	
// 	local browser = vgui.Create('DFileBrowser', SoundBrowser)
// 	browser:Dock(FILL)
// 	browser:SetPath('GAME') 
// 	browser:SetBaseFolder('sound') 
// 	browser:SetOpen(true) 

// 	function browser:OnDoubleClick(path, _)
// 		if SoundBrowser.soundobj then
// 			SoundBrowser.soundobj:Stop()
// 			SoundBrowser.soundobj = nil	
// 		end
// 		SoundBrowser.soundobj = CreateSound(LocalPlayer(), string.sub(path, 7, -1))
// 		SoundBrowser.soundobj:PlayEx(1, 100)
// 	end

// 	function SoundBrowser:OnRemove()
// 		if SoundBrowser.soundobj then
// 			SoundBrowser.soundobj:Stop()
// 			SoundBrowser.soundobj = nil	
// 		end
// 	end
// end

// OpenMaterialsBrowser(0, 0, 500, 500)
// // OpenSoundBrowser(0, 0, 500, 500)

// Editor = nil
// local function OpenEditor(filename)
// 	if IsValid(Editor) then Editor:Remove() end

// 	local fcmddata, filename = fcmd_LoadFcmdDataFromFile(filename)
// 	if not istable(fcmddata) then return end

// 	local scrw, scrh = ScrW(), ScrH()

// 	-- 编辑器窗口定义
// 	Editor = vgui.Create('DFrame')
// 	Editor:SetTitle('#fcmd.ui.title.editor')
// 	Editor:SetSize(scrw * 0.6, scrh * 0.7)
// 	Editor:Center()
// 	Editor:SetSizable(true)
// 	Editor:MakePopup()
// 	Editor:SetDeleteOnClose(true)

// 	function Editor:OnRemove()
// 		fcmd_SaveFcmdDataToFile(fcmddata, filename, true)
// 		fcmdm_ReloadCurrentFcmdData(filename)
// 		if IsValid(SoundBrowser) then SoundBrowser:Remove() end
// 		if IsValid(MaterialsBrowser) then MaterialsBrowser:Remove() end
// 	end

// 	-- 预览与编辑器主体定义
// 	local ViewPort = vgui.Create('DPanel', Editor)
// 	local Main = vgui.Create('DPanel', Editor)
// 	local div = vgui.Create('DHorizontalDivider', Editor)
	
// 	div:Dock(FILL)
// 	div:SetLeft(ViewPort)
// 	div:SetRight(Main)
// 	div:SetDividerWidth(4)
// 	div:SetLeftMin(20) 
// 	div:SetRightMin(20)
// 	div:SetLeftWidth(250)
	
// 	ViewPort.fcmddata = fcmddata
// 	Main.fcmddata = fcmddata

// 	function ViewPort:Paint(w, h)
// 		draw.RoundedBox(5, 0, 0, w, h, background)
// 		if istable(self.fcmddata) then
// 			local succ = SafeDrawHud2D(
// 				self.size, 
// 				self.fcmddata, 
// 				1, 
// 				self.previewtrans
// 			)
// 			if not succ then self.fcmddata = nil end
// 		end
// 	end

// 	function ViewPort:OnSizeChanged(newWidth, newHeight)
// 		self.previewtrans = {
// 			x = 0,
// 			y = 0,
// 			w = newWidth,
// 			h = newHeight,
// 		}
// 		self.size = min(newWidth, newHeight) * 0.5
// 	end

// 	Main.Paint = emptyfunc

// 	-- 根属性编辑器与节点属性编辑器定义
// 	local RootAttrs = vgui.Create('DPanel', Main)
// 	local MetadataAttrs = vgui.Create('DPanel', Main)

// 	local div2 = vgui.Create('DVerticalDivider', Main)
	
// 	div2:Dock(FILL)
// 	div2:SetTop(RootAttrs)
// 	div2:SetBottom(MetadataAttrs)
// 	div2:SetDividerHeight(4)
// 	div2:SetTopMin(20) 
// 	div2:SetBottomMin(20)
// 	div2:SetTopHeight(150)

// 	local function CreateMaterialInput(label, parent)
// 		local matinput = vgui.Create('DPanel', parent)
// 		local label = vgui.Create('DLabel', matinput)
// 		local txtinput = vgui.Create('DTextEntry', matinput)
// 		local browserbtn = vgui.Create('DButton', matinput)

// 		function matinput:OnSizeChanged(nw, nh)
// 			label:SetPos(0, 0)
// 			label:SetSize(0.2 * nw, nh)

// 			txtinput:SetPos(0.2 * nw, 0)
// 			txtinput:SetSize(0.6 * nw, nh)

// 			browserbtn:SetPos(0.8 * nw, 0)
// 			browserbtn:SetSize(0.2 * nw, nh)	 
// 		end

// 		browserbtn:SetText('#fcmd.ui.title.material_browser')
// 		browserbtn.DoClick = function(self)
// 			local x, y = self:LocalToScreen(0, 0)
// 			OpenMaterialsBrowser(x, y - 250, 300, 300)
// 		end

// 		matinput.label = label
// 		matinput.txtinput = txtinput

// 		return matinput
// 	end

// 	-- 根属性编辑器部分
// 	local ciconbtn = CreateMaterialInput('fcmd.ui.cicon', RootAttrs)

// 	// local arrow = CreateMaterialInput(RootAttrs)
// 	// local edge = CreateMaterialInput(RootAttrs)
// 	// local transform3dbtn = vgui.Create('DButton', RootAttrs)
// 	// local autoclip = vgui.Create('DButton', RootAttrs)
// 	// local centersize = vgui.Create('DSlider', RootAttrs)
// 	// local iconsize = vgui.Create('DSlider', RootAttrs)
// 	// local fade = vgui.Create('DSlider', RootAttrs)

// 	function RootAttrs:OnSizeChanged(nw, nh)
// 		ciconbtn:SetPos(0, 0)
// 		ciconbtn:SetSize(300, 20)

// 		// arrow:SetPos(20, 0)
// 		// arrow:SetSize(20, 20)

// 		// edge:SetPos(40, 0)
// 		// edge:SetSize(20, 20)

// 		// transform3dbtn:SetPos(40, 0)
// 		// transform3dbtn:SetSize(20, 20)
// 	end
// end
// // OpenEditor('aaa')


