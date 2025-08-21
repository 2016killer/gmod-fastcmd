
include('../core/fcmd_file.lua')
local rootpath = 'fastcmd/wheel'
local min, max = math.min, math.max

local function EnumPathNoExist(filePath)
	local path = string.GetPathFromFilename(filePath)
	local ext = string.GetExtensionFromFilename(filePath)
	local name = string.StripExtension(string.GetFileFromFilename(filePath))
	ext = ext and ('.'..ext) or ''

	local succ = false
	for i = 0, 2 do
		local newtarget = i == 0 and filePath or (path..name..' ('..i..')'..ext)
		if not file.Exists(newtarget, 'DATA') then
			filePath = newtarget
			succ = true
			break
		end
	end

	if succ then
		return filePath
	else
		return nil
	end
end
--------------------------------
local WheelDataBrowser
function FcmduCreateWheelDataBrowser(parent)
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

		local edit = menu:AddOption('#fcmdu.edit', function()
			LocalPlayer():ConCommand(string.format('fcmdu_open_editor "%s"', filePath))
		end)
		edit:SetImage('materials/icon16/application_edit.png')

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
		
		local rename = menu:AddOption('#fcmdu.rename', function()
			local frame = vgui.Create('DFrame')
			frame:SetSize(250, 100)
			frame:Center()
			frame:SetTitle('#fcmdu.rename')
			frame:MakePopup()

			local nameinput = vgui.Create('DTextEntry', frame)
			nameinput:SetPos(10, 30)
			nameinput:SetSize(230, 20)
			nameinput:SetText(
				string.StripExtension(string.GetFileFromFilename(filePath))
			)

			local okbtn = vgui.Create('DButton', frame)
			okbtn:SetPos(10, 60)
			okbtn:SetSize(110, 20)
			okbtn:SetText('#fcmdu.submit')
			okbtn.DoClick = function()
				local name = nameinput:GetValue()
				name = string.Trim(string.GetFileFromFilename(name))
				if name == '' then return end
				if string.GetExtensionFromFilename(name) ~= 'json' then
					name = name .. '.json'
				end

				local newpath = string.GetPathFromFilename(filePath)..name
				if newpath == filePath then
					frame:Remove()
					return
				end

				newpath = EnumPathNoExist(newpath)
				if newpath == nil then
					FcmdError('#fcmdu.err.rename', '#fcmdu.exist')
				else
					file.Rename(filePath, newpath)
					frame:Remove()
					FileBrowser:Refresh()
				end
			end

			local cancelbtn = vgui.Create('DButton', frame)
			cancelbtn:SetPos(130, 60)
			cancelbtn:SetSize(110, 20)
			cancelbtn:SetText('#fcmdu.cancel')
			cancelbtn.DoClick = function()
				frame:Remove()
			end

		end)
		rename:SetImage('materials/icon16/basket_edit.png')

		local delete = menu:AddOption('#fcmdu.delete', function()
			local succ, err = pcall(FcmdDeleteJsonFile, filePath)
			if succ then 
				succ = err
				if succ then 
					if GetConVar('cl_fcmdm_wfile'):GetString() == filePath then
						FcmdmClearCurWData()
					end

					surface.PlaySound('Buttons.snd15') 
				end
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

concommand.Add('fcmdu_open_wheel_wdatabrow', function()
	local frame = vgui.Create('DFrame')
	frame:MakePopup()
	frame:SetSize(500, 500)
	frame:Center()
	frame:SetDeleteOnClose(true)
	FcmduCreateWheelDataBrowser(frame)
end)


