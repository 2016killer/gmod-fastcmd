
include('../core/fcmd_file.lua')
local rootpath = 'fastcmd/wheel'
local min, max = math.min, math.max


--------------------------------
local WheelDataBrowser
function FcmdCreateWheelDataBrowser(parent)
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
	CreateNewBtn:SetText('#fcmdu.create')
	CreateNewBtn:Dock(BOTTOM)
	CreateNewBtn:DockMargin(0, 5, 0, 5)

	local FileBrowser = vgui.Create('DFileBrowser', WheelDataBrowser)
	FileBrowser:Dock(FILL)
	FileBrowser:SetPath('DATA') 
	FileBrowser:SetBaseFolder(rootpath) 
	FileBrowser:SetCurrentFolder(rootpath) 
	FileBrowser:SetOpen(true)

	function FileBrowser:OnRightClick(filePath, selectedPanel) 
		local menu = DermaMenu() 

		local apply = menu:AddOption('#fcmdu.apply', function()
			FcmdmLoadCurWData(filePath)
		end)
		apply:SetImage('materials/icon16/application_lightning.png')

		menu:AddSpacer()

		local copy = menu:AddOption('#fcmdu.copy', function()
			local succ, err = pcall(FcmdCopyJsonFile, filePath, filePath)
			if not succ then 
				ErrorNoHaltWithStack(err)
			end
			FileBrowser:Refresh()
		end)
		copy:SetImage('materials/icon16/application_double.png')

		local copycontent = menu:AddOption('#fcmdu.copy_content', function() 
			FcmdCopyJsonFileContent(filePath)
		end)
		copycontent:SetImage('materials/icon16/application_double.png')
		
		menu:AddSpacer()
		
		local edit = menu:AddOption('#fcmdu.edit', function() end)
		edit:SetImage('materials/icon16/application_edit.png')

		local delete = menu:AddOption('#fcmdu.delete', function()
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

// concommand.Add('fcmd_open_wheel_wdatabrow', )

