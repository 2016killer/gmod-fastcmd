// SoundBrowser = nil
// local function OpenSoundBrowser()
// 	if IsValid(SoundBrowser) then SoundBrowser:Remove() end

// 	SoundBrowser = vgui.Create('DFrame')
// 	SoundBrowser:SetTitle('#fcmdu.title.sound_browser')
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

// 	function browser:OnDoubleClick(path)
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
