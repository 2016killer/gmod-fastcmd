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
	local label = vgui.Create('DLabel', panel)
	local input = vgui.Create('DTextEntry', panel)
	local openbtn = vgui.Create('DButton', panel)
	label:SetText(txt)
	openbtn:SetText('#fcmdu.browse')

	label:SetColor(Color(0, 0, 0))

	panel:Dock(FILL)
	label:Dock(TOP)
	openbtn:Dock(RIGHT)
	input:Dock(FILL)

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

	return input
end


// local frame = vgui.Create('DFrame')
// frame:SetSize(500, 100)
// frame:Center()
// frame:MakePopup()
// frame:SetKeyBoardInputEnabled(true)
// FcmdCreateSoundInput('音效', frame)