local SoundsBrowser = nil
function FcmduOpenSoundsBrowser()
	if IsValid(SoundsBrowser) then SoundsBrowser:Remove() end

	SoundsBrowser = vgui.Create('DFrame')
	SoundsBrowser:SetTitle('#fcmdu.title.sound_browser')
	SoundsBrowser:SetSize(500, 500)
	SoundsBrowser:Center()
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
	
	return SoundsBrowser
end

concommand.Add('fcmdu_open_soundbrow', function()
	FcmduOpenSoundsBrowser()
end)





