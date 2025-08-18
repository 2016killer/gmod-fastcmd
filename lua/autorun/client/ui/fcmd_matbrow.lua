local min, max = math.min, math.max

local function SetMaterial(mat)
	if istable(mat) then
		-- 处理异步材质
		surface.SetMaterial(mat.mat)
	else
		surface.SetMaterial(mat)
	end
end

local icondefault = Material('fastcmd/hud/default.jpg')
----------------------------
local MaterialsBrowser
local page = 1
local filterinput = ''
function FcmdOpenMaterialsBrowser()
	if IsValid(MaterialsBrowser) then MaterialsBrowser:Remove() end
	local scrw, scrh = ScrW(), ScrH()
	
	MaterialsBrowser = vgui.Create('DFrame')
	MaterialsBrowser:SetTitle('#fcmdu.title.material_browser')
	MaterialsBrowser:SetSize(scrw * 0.5, scrh * 0.5)
	MaterialsBrowser:Center()
	MaterialsBrowser:SetSizable(true)
	MaterialsBrowser:MakePopup()
	MaterialsBrowser:SetDeleteOnClose(true)
	MaterialsBrowser:SetMinimumSize(120 , 100)
	MaterialsBrowser.selectmaterial = nil
	MaterialsBrowser.selectFile = nil

	local Tabs = vgui.Create('DPropertySheet', MaterialsBrowser)
	local ViewPort = vgui.Create('DPanel', MaterialsBrowser)
	local Div = vgui.Create('DHorizontalDivider', MaterialsBrowser)
	local SubmitBtn = vgui.Create('DButton', MaterialsBrowser)

	SubmitBtn:SetText('#fcmdu.submit')
	SubmitBtn:SetHeight(30)
	SubmitBtn:Dock(BOTTOM)

	Div:Dock(FILL)
	Div:SetLeft(Tabs)
	Div:SetRight(ViewPort)
	Div:SetDividerWidth(4)
	Div:SetLeftMin(20) 
	Div:SetRightMin(20)
	Div:SetLeftWidth(scrw * 0.5 * 0.7)

	local background = Color(255, 255, 255, 200)
	function ViewPort:Paint(w, h)
		draw.RoundedBox(5, 0, 0, w, h, background)
		if MaterialsBrowser.selectmaterial then
			local matWidth = min(w, h)
			local cx, cy = (w - matWidth) * 0.5, (h - matWidth) * 0.5
			surface.SetDrawColor(255, 255, 255, 255)
			SetMaterial(MaterialsBrowser.selectmaterial)
			surface.DrawTexturedRect(cx, cy, matWidth, matWidth)
		end
	end
	----
	local AddonBrowser = vgui.Create('DPanel', Tabs)
	local AddonFilterInput = vgui.Create('DTextEntry', AddonBrowser)
	local AddonTree = vgui.Create('DTree', AddonBrowser)
	local ButtonPanel = vgui.Create('DPanel', AddonBrowser)
	local LastBtn = vgui.Create('DButton', ButtonPanel)
	local NextBtn = vgui.Create('DButton', ButtonPanel)
	local PageLabel = vgui.Create('DLabel', ButtonPanel)

	AddonFilterInput:Dock(TOP)
	AddonTree:Dock(FILL)
	ButtonPanel:Dock(BOTTOM)

	LastBtn:SetText('#fcmdu.last_page')
	NextBtn:SetText('#fcmdu.next_page')

	LastBtn:Dock(LEFT)
	NextBtn:Dock(LEFT)
	NextBtn:DockMargin(10, 0, 10, 0)
	PageLabel:Dock(LEFT)
	PageLabel:SetColor(Color(0, 0, 0))

	local pnum = 20
	local addonsfilter = {}
	
	function AddonTree:OnNodeSelected()
		local wsid = self:GetSelectedItem().wsid
		MaterialsBrowser.selectmaterial = FcmdLoadMaterials(wsid, icondefault)
		MaterialsBrowser.selectFile = wsid

		if isfunction(MaterialsBrowser.OnSelect) then
			MaterialsBrowser:OnSelect(MaterialsBrowser.selectFile, MaterialsBrowser.selectmaterial)
		end
	end

	function AddonBrowser:Search(str)
		filterinput = str
		if str == '' then
			addonsfilter = engine.GetAddons()
		else
			addonsfilter = {}
			local lowerSearchStr = string.lower(str)
			for _, addon in pairs(engine.GetAddons()) do
				if addon.wsid ~= '' and string.find(string.lower(addon.title), lowerSearchStr, 1, true) then
					table.insert(addonsfilter, addon)
				end
			end
		end
	end

	function AddonBrowser:GetPage()
		return page
	end

	function AddonBrowser:SetPage(num)
		AddonTree:Clear()
		local pagemax = math.max(1, math.ceil(#addonsfilter / pnum))
		page = math.Clamp(num, 1, pagemax) 

		local start = (page - 1) * pnum + 1
		local ed = min(page * pnum, #addonsfilter)
		for i = start, ed do
			local addon = addonsfilter[i]
			local wsid = addon.wsid
			if wsid ~= '' then
				local node = AddonTree:AddNode(addon.title or '', 'icon16/page.png')
				node.wsid = wsid	
			end
		end

		PageLabel:SetText(tostring(page) .. '/' .. tostring(pagemax))
	end


	LastBtn.DoClick = function()
		AddonBrowser:SetPage(AddonBrowser:GetPage() - 1)
	end

	NextBtn.DoClick = function()
		AddonBrowser:SetPage(AddonBrowser:GetPage() + 1)
	end

	function AddonFilterInput:OnValueChange(value)
		AddonBrowser:Search(value)
		AddonBrowser:SetPage(1)
	end
	----
	local GameMatBrowser = vgui.Create('DPanel', Tabs)
	local FileBrowser = vgui.Create('DFileBrowser', GameMatBrowser)

	FileBrowser:Dock(FILL)
	FileBrowser:SetPath('GAME') 
	FileBrowser:SetBaseFolder('materials') 
	FileBrowser:SetOpen(true) 

	function FileBrowser:OnSelect(filePath, _) 
		local matfile = string.sub(filePath, 11, -1)
		MaterialsBrowser.selectmaterial = Material(matfile)
		MaterialsBrowser.selectFile = matfile

		if isfunction(MaterialsBrowser.OnSelect) then
			MaterialsBrowser:OnSelect(MaterialsBrowser.selectFile, MaterialsBrowser.selectmaterial)
		end
	end

	function FileBrowser:OnRightClick(filePath, _) 
		local menu = DermaMenu() 
		local copy = menu:AddOption('#fcmdu.copy', function() 
			SetClipboardText(string.sub(filePath, 11, -1)) 
		end)
		copy:SetImage('materials/icon16/application_double.png')
		
		local apply = menu:AddOption('#fcmdu.apply', function() 
		
		end)
		apply:SetImage('materials/icon16/application_lightning.png')

		menu:Open()
	end

	Tabs:AddSheet('#fcmdu.title.addon', AddonBrowser, 'icon16/bricks.png', false, false, '')
	Tabs:AddSheet('#fcmdu.title.game', GameMatBrowser, 'materials/icon16/add.png', false, false, '')
	
	AddonBrowser:Search(filterinput)
	AddonBrowser:SetPage(page)
end

concommand.Add('fcmdu_open_matbrow', function()
	FcmdOpenMaterialsBrowser()
end)

function FcmdCreateMaterialsInput(label, parent)
	local panel = vgui.Create('DPanel', parent)
	local label = vgui.Create('DLabel', panel)
	local input = vgui.Create('DTextEntry', panel)
	local openbtn = vgui.Create('DButton', panel)
	openbtn:SetText('#fcmdu.browse')
	openbtn.DoClick = function()
		FcmdOpenMaterialsBrowser()
		function MaterialsBrowser:OnSelect(file, mat)
			input:SetValue(file)
			input.mat = mat
		end
	end

	panel:Dock(FILL)

	label:Dock(TOP)
	openbtn:Dock(RIGHT)
	input:Dock(FILL)

	return input
end


print(language.GetPhrase(''))
