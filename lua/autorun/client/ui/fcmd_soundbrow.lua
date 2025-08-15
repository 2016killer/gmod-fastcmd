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


