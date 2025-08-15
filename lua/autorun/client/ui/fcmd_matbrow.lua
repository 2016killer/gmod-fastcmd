local min, max = math.min, math.max

MaterialsBrowser = nil
local function OpenMaterialsBrowser()
	if IsValid(MaterialsBrowser) then MaterialsBrowser:Remove() end
	local scrw, scrh = ScrW(), ScrH()

	MaterialsBrowser = vgui.Create('DFrame')
	MaterialsBrowser:SetTitle('#fcmd.ui.title.material_browser')
	MaterialsBrowser:SetSize(scrw * 0.5, scrh * 0.5)
	MaterialsBrowser:Center()
	MaterialsBrowser:SetSizable(true)
	MaterialsBrowser:MakePopup()
	MaterialsBrowser:SetDeleteOnClose(true)
	MaterialsBrowser:SetMinimumSize(120 , 100)

	local tabs = vgui.Create('DPropertySheet', MaterialsBrowser)
	local submitbtn = vgui.Create('DButton', MaterialsBrowser)

	submitbtn:SetText('#fcmd.ui.submit')
	tabs:Dock(FILL)
	submitbtn:Dock(BOTTOM)
	----
	local addonMatBrowser = vgui.Create('DPanel', MaterialsBrowser)
	local addonMatBrowserDiv = vgui.Create('DHorizontalDivider', addonMatBrowser)
	local addonViewPort = vgui.Create('DPanel', addonMatBrowser)
	local addonSelectPanel = vgui.Create('DPanel', addonMatBrowser)

	local addonSearch = vgui.Create('DTextEntry', addonSelectPanel)
	local addonTree = vgui.Create('DTree', addonSelectPanel)
	local addonMat
	
	tabs:AddSheet('#fcmd.ui.title.addon', addonMatBrowser, 'icon16/bricks.png', false, false, '')
	addonMatBrowser.Paint = emptyfunc

	addonMatBrowserDiv:Dock(FILL)
	addonMatBrowserDiv:SetLeft(addonSelectPanel)
	addonMatBrowserDiv:SetRight(addonViewPort)
	addonMatBrowserDiv:SetDividerWidth(4)
	addonMatBrowserDiv:SetLeftMin(20) 
	addonMatBrowserDiv:SetRightMin(20)
	addonMatBrowserDiv:SetLeftWidth(scrw * 0.5 * 0.7)
	local background = Color(255, 255, 255, 200)
	function addonViewPort:Paint(w, h)
		draw.RoundedBox(5, 0, 0, w, h, background)
		if addonMat then
			local matWidth = min(w, h)
			local cx, cy = (w - matWidth) * 0.5, (h - matWidth) * 0.5
			surface.SetDrawColor(255, 255, 255, 255)
			surface.SetMaterial(addonMat)
			surface.DrawTexturedRect(cx, cy, matWidth, matWidth)
		end
	end

	addonSearch:Dock(TOP)
	addonTree:Dock(FILL)

	for _, addon in ipairs(engine.GetAddons()) do 
		local file_ = addon.file
		if file ~= '' then
			local node = addonTree:AddNode(addon.title or '', 'icon16/page.png')
			node.file = file_	
		end
	end

	function addonTree:OnNodeSelected()
		// local addonMat = AddonMaterial('895632296.gma')
	end
	----
	local gameMatBrowser = vgui.Create('DPanel', MaterialsBrowser)
	local gameViewPort = vgui.Create('DPanel', gameMatBrowser)
	local gameMatFileBrowser = vgui.Create('DFileBrowser', gameMatBrowser)
	local div = vgui.Create('DHorizontalDivider', gameMatBrowser)
	local gamemat

	tabs:AddSheet('#fcmd.ui.title.game', gameMatBrowser, 'materials/icon16/add.png', false, false, '')
	gameMatBrowser.Paint = emptyfunc

	div:Dock(FILL)
	div:SetLeft(gameMatFileBrowser)
	div:SetRight(gameViewPort)
	div:SetDividerWidth(4)
	div:SetLeftMin(20) 
	div:SetRightMin(20)
	div:SetLeftWidth(scrw * 0.5 * 0.7)
	
	gameMatFileBrowser:SetPath('GAME') 
	gameMatFileBrowser:SetBaseFolder('materials') 
	gameMatFileBrowser:SetOpen(true) 

	function gameViewPort:Paint(w, h)
		draw.RoundedBox(5, 0, 0, w, h, background)
		if selectmaterial then
			local matWidth = min(w, h)
			local cx, cy = (w - matWidth) * 0.5, (h - matWidth) * 0.5
			surface.SetDrawColor(255, 255, 255, 255)
			surface.SetMaterial(selectmaterial)
			surface.DrawTexturedRect(cx, cy, matWidth, matWidth)
		end
	end

	function gameMatFileBrowser:OnSelect(path, pnl) 
		selectmaterial = Material(string.sub(path, 11, -1))
	end

	function gameMatFileBrowser:OnRightClick(filePath, selectedPanel) 
		local menu = DermaMenu() 
		menu:AddOption('#fcmd.ui.copy', function() SetClipboardText(filePath) end)
		menu:AddOption('#fcmd.ui.apply', function()  end)
		
		menu:Open()
	end

end
OpenMaterialsBrowser()


