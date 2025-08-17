
include('../core/fcmd_file.lua')
local rootpath = 'fastcmd'
local min, max = math.min, math.max
local FcmdDrawWheel2D = FcmdDrawWheel2D

// local function SafeDrawHud2D(size, fcmddata, state, preview)
// 	local succ, err = pcall(FcmdDrawWheel2D, size, fcmddata, state, preview)
// 	if not succ then
// 		ErrorNoHaltWithStack(err)
// 		FcmdError('#fcmd.err.fatal', '#fcmd.err.data')

// 		render.ClearStencil()
// 		render.SetStencilEnable(false)
// 		render.OverrideColorWriteEnable(false)
// 		gui.EnableScreenClicker(false)
// 	end
// 	return succ
// end

--------------------------------
local WheelDataBrowser
function CreateWheelDataBrowser(parent)
	-- 数据列表
	if not IsValid(parent) then return end
	if IsValid(WheelDataBrowser) then WheelDataBrowser:Remove() end

	WheelDataBrowser = vgui.Create('DPanel', parent)
	WheelDataBrowser:Dock(FILL)
	WheelDataBrowser:DockMargin(5, 5, 5, 5)

	WheelDataBrowser.Paint = function() end

	local TopNavigation = vgui.Create('DPanel', WheelDataBrowser)
	TopNavigation:SetHeight(20)
	TopNavigation:Dock(TOP)
	TopNavigation:DockMargin(0, 0, 0, 5)

	local RefreshBtn = vgui.Create('DImageButton', TopNavigation)
	RefreshBtn:SetWidth(16)
	RefreshBtn:Dock(LEFT)
	RefreshBtn:SetImage('icon16/arrow_refresh.png')
	RefreshBtn:DockMargin(5, 0, 0, 0)

	local CreateNewBtn = vgui.Create('DButton', WheelDataBrowser)
	CreateNewBtn:SetWidth(WheelDataBrowser:GetWide())
	CreateNewBtn:SetText('#fcmd.ui.create')
	CreateNewBtn:Dock(BOTTOM)
	CreateNewBtn:DockMargin(0, 5, 0, 5)

	local FileBrowser = vgui.Create('DFileBrowser', WheelDataBrowser)
	FileBrowser:Dock(FILL)
	FileBrowser:SetPath('DATA') 
	FileBrowser:SetBaseFolder('fastcmd/wheel') 
	FileBrowser:SetCurrentFolder('fastcmd/wheel') 
	FileBrowser:SetOpen(true)

	function FileBrowser:OnRightClick(filePath, selectedPanel) 
		local menu = DermaMenu() 

		local apply = menu:AddOption('#fcmd.ui.apply', function()
			FcmdmLoadCurWData(filePath)
		end)
		apply:SetImage('materials/icon16/application_lightning.png')

		menu:AddSpacer()

		local copy = menu:AddOption('#fcmd.ui.copy', function()
			local succ, err = pcall(FcmdCopyJsonFile, filePath, filePath)
			if not succ then 
				ErrorNoHaltWithStack(err)
			end
			FileBrowser:Refresh()
		end)
		copy:SetImage('materials/icon16/application_double.png')

		local copycontent = menu:AddOption('#fcmd.ui.copy_content', function() 
			FcmdCopyJsonFileContent(filePath)
		end)
		copycontent:SetImage('materials/icon16/application_double.png')
		
		menu:AddSpacer()
		
		local edit = menu:AddOption('#fcmd.ui.edit', function() end)
		edit:SetImage('materials/icon16/application_edit.png')

		local delete = menu:AddOption('#fcmd.ui.delete', function()
			local succ, err = pcall(FcmdDeleteJsonFile, filePath)
			if succ then 
				succ = err
				if succ then surface.PlaySound('Buttons.snd15') end
			else
				ErrorNoHaltWithStack(err)
			end
			FileBrowser:Refresh()
		end)
		delete:SetImage('materials/icon16/application_delete.png')

		menu:Open()
	end

	function FileBrowser:Refresh()
		self:SetCurrentFolder(self:GetCurrentFolder()) 
	end

	function FileBrowser:CreateNew()
		surface.PlaySound('garrysmod/ui_click.wav')
		FcmdCreateWheelData(self:GetCurrentFolder())
		self:Refresh()
	end

	RefreshBtn.DoClick = function()
		FileBrowser:Refresh()
	end

	CreateNewBtn.DoClick = function()
		FileBrowser:CreateNew()
	end

	function FileBrowser:OnDoubleClick(filePath)
		FcmdmLoadCurWData(filePath)
	end

	function FileBrowser:OnSelect(filePath)
		WheelDataBrowser.selectFile = filePath
	end

	function WheelDataBrowser:Refresh()
		FileBrowser:Refresh()
		self.selectFile = nil
	end

	return WheelDataBrowser
end



// --------------------------------
// function FastCmdDataManager:SelectFile(filename)
// 	filename = isstring(filename) and filename or ''
// 	self.selectfile = filename
// 	self.title:SetText(language.GetPhrase('#fcmd.ui.select')..(filename == '' and 'None' or filename))
// 	self.saveAsState = 0
// 	self.deleteState = 0
// 	if self.preview then
// 		self.fcmddata = fcmd_LoadFcmdDataFromFile(filename)
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
// 	local progress = fcmd_SaveAsProgress(target, state == 0)
	
// 	if progress then
// 		state = state + progress
// 	else
// 		state = 0
// 	end
// 	self.saveAsState = state

// 	if state >= 2 then
// 		local succ = fcmd_SaveAs(origin, target)
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
// 		FcmdWarn('#fcmd.warn.delete')
// 		return false
// 	elseif self.deleteState >= 2 then
// 		self.deleteState = 0
// 		local succ = fcmd_Delete(filename)
// 		if succ then
// 			LocalPlayer():ConCommand('cl_fcmd_wfile ""')
// 			surface.PlaySound('Buttons.snd15')
// 			self:UpdateFileList()
// 		end
// 		return succ
// 	end
// 	return false
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
