local SoundsBrowser = nil
local function FcmdOpenSoundsBrowser()
	if IsValid(SoundsBrowser) then SoundsBrowser:Remove() end

	SoundsBrowser = vgui.Create('DFrame')
	SoundsBrowser:SetTitle('#fcmdu.title.sound_browser')
	SoundsBrowser:SetPos(x or 0, y or 0)
	SoundsBrowser:SetSize(w or 500, h or 500)
	SoundsBrowser:SetSizable(true)
	SoundsBrowser:MakePopup()
	SoundsBrowser:SetDeleteOnClose(true)
	SoundsBrowser.soundobj = nil
    SoundsBrowser.selectFile = nil
	
	local browser = vgui.Create('DFileBrowser', SoundsBrowser)
	browser:Dock(FILL)
	browser:SetPath('GAME') 
	browser:SetBaseFolder('sound') 
	browser:SetOpen(true) 

	function browser:OnDoubleClick(path)
		if SoundsBrowser.soundobj then
			SoundsBrowser.soundobj:Stop()
			SoundsBrowser.soundobj = nil	
		end
        SoundsBrowser.selectFile = string.sub(path, 7, -1)
		SoundsBrowser.soundobj = CreateSound(LocalPlayer(), SoundsBrowser.selectFile)
		SoundsBrowser.soundobj:PlayEx(1, 100)

        if isfunction(SoundsBrowser.OnSelect) then
            SoundsBrowser:OnSelect(SoundsBrowser.selectFile)
        end
	end

	function SoundsBrowser:OnRemove()
		if SoundsBrowser.soundobj then
			SoundsBrowser.soundobj:Stop()
			SoundsBrowser.soundobj = nil	
		end
	end
end

concommand.Add('fcmdu_open_soundbrow', function()
	FcmdOpenSoundsBrowser()
end)

function FcmdCreateSoundInput(txt, parent)
	local panel = vgui.Create('DPanel', parent)
	panel:SetSize(180, 20)

	local label = vgui.Create('DLabel', panel)
	label:SetText(txt)
	label:SetPos(0, 0)

	local input = vgui.Create('DTextEntry', panel)
	input:SetPos(50, 0)
	input:SetSize(100, 20)

	local openbtn = vgui.Create('DButton', panel)
	openbtn:SetText('#fcmdu.browse')
	openbtn:SetPos(150, 0)
	openbtn:SetSize(30, 20)
	
	openbtn.DoClick = function()	
		FcmdOpenSoundsBrowser()

		local openfolder = string.GetPathFromFilename(input:GetText())
		if string.Trim(openfolder) ~= '' then SoundsBrowser:SetCurrentFolder(openfolder) end
		function SoundsBrowser:OnSelect(file)
			input:SetValue(file)
		end
	end

	function panel:OnRemove()
		if IsValid(SoundsBrowser) then SoundsBrowser:Remove() end
	end

	function input:OnValueChange(value)
		if isfunction(panel.OnValueChange) then
			panel:OnValueChange(value)
		end
	end

	function panel:SetValue(value)
		input:SetValue(value)
	end	
	
	function panel:GetValue()
		return input:GetValue()
	end

	panel.Paint = function() end

	return panel
end

// local frame = vgui.Create('DFrame')
// frame:SetSize(500, 100)
// frame:Center()
// frame:MakePopup()
// frame:SetKeyBoardInputEnabled(true)
// FcmdCreateSoundInput('音效', frame)