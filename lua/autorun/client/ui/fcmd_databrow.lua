
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


	local CreateNewBtn = vgui.Create('DButton', parent)
	CreateNewBtn:SetWidth(parent:GetWide())
	CreateNewBtn:SetText('#fcmd.ui.create')
	CreateNewBtn:Dock(BOTTOM)
	CreateNewBtn:DockMargin(0, 5, 0, 5)

	local EditorBtn = vgui.Create('DButton', parent)
	EditorBtn:SetWidth(parent:GetWide())
	EditorBtn:SetText('#fcmd.ui.editor')
	EditorBtn:Dock(BOTTOM)
	EditorBtn:DockMargin(0, 5, 0, 5)

	WheelDataBrowser = vgui.Create('DPanel', parent)
	WheelDataBrowser:Dock(FILL)
	WheelDataBrowser:DockMargin(5, 5, 5, 5)

	local SearchPanel = vgui.Create('DPanel', WheelDataBrowser)
	SearchPanel:SetHeight(20)
	SearchPanel:Dock(TOP)
	SearchPanel:DockMargin(5, 5, 5, 5)

	local RefreshBtn = vgui.Create('DImageButton', SearchPanel)
	RefreshBtn:SetWidth(20)
	RefreshBtn:Dock(RIGHT)
	RefreshBtn:SetImage('icon16/arrow_refresh.png')

	local SearchInput = vgui.Create('DTextEntry', SearchPanel)
	SearchInput:Dock(FILL)
	SearchInput:DockMargin(0, 0, 5, 0)

	local FileBrowser = vgui.Create('DFileBrowser', WheelDataBrowser)
	FileBrowser:Dock(FILL)
	FileBrowser:SetPath('DATA') 
	FileBrowser:SetBaseFolder('fastcmd') 
	FileBrowser:SetOpen(true) 

	function FileBrowser:OnRightClick(filePath, selectedPanel) 
		local menu = DermaMenu() 

		local apply = menu:AddOption('#fcmd.ui.apply', function() end)
		apply:SetImage('materials/icon16/application_lightning.png')
		
		menu:AddSpacer()
		
		local copy = menu:AddOption('#fcmd.ui.copy', function() end)
		copy:SetImage('materials/icon16/application_double.png')

		local copyclip = menu:AddOption('#fcmd.ui.copy_to_clipboard', function() SetClipboardText(filePath) end)
		copyclip:SetImage('materials/icon16/application_double.png')
		
		menu:AddSpacer()
		
		local edit = menu:AddOption('#fcmd.ui.edit', function() end)
		edit:SetImage('materials/icon16/application_edit.png')

		local delete = menu:AddOption('#fcmd.ui.delete', function() end)
		delete:SetImage('materials/icon16/application_delete.png')

		menu:Open()
	end

	function FileBrowser:OnSelect(filePath)
		WheelDataBrowser.OpenPath = string.GetPathFromFilename(filePath)
	end

	// function PANEL:DoClick()
	// 	self:SetOpenPath(string.GetPathFromFilename(file))

	// 	local file = self:GetOpenFile()
	// 	local page = self:GetPage()

	// 	self.bSetup = self:Setup()

	// 	self:SetOpenFile(file)
	// 	self:SetPage(page)
	// end


	function FileBrowser:OnDoubleClick(filePath)
		print(filePath)
	end


	// WheelDataBrowser:MakePopup()
	// WheelDataBrowser:SetKeyBoardInputEnabled(true)
	return WheelDataBrowser
end
local frame = vgui.Create('DFrame')
frame:SetSize(500, 500)
frame:Center()
frame:MakePopup()
frame:SetKeyBoardInputEnabled(true)
frame:SetSizable(true)
CreateWheelDataBrowser(frame)


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

// function FastCmdDataManager:UpdateFileList()
// 	self:SelectFile()
// 	timer.Simple(0.5, self.datalist.UpdateFileList)
// 	FcmdProgress('#fcmd.ui.loading')
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
