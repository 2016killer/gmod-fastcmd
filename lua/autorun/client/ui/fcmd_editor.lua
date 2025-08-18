min, max = math.min, math.max

include('../core/fcmd_wheel.lua') 
local DrawWheel2D = FcmdDrawWheel2D
local DrawBounds = FcmdDrawBounds

local function SafeDrawDrawWheel2D(size, wdata, preview)
    local succ1, err1 = pcall(DrawWheel2D, size, wdata, 1, preview)
    local succ2, err2 = pcall(DrawBounds, size, wdata, preview)

    local succ = succ1 and succ2
	if not succ then
		render.ClearStencil()
		render.SetStencilEnable(false)
		render.OverrideColorWriteEnable(false)

		if not succ1 then ErrorNoHaltWithStack(err1) end
        if not succ2 then ErrorNoHaltWithStack(err2) end
        FcmdError('#fcmdu.err.fatal', '#fcmdu.err.data')
	end

	return succ
end

local function AddItem(parent, child, layout)
    local row = parent.row or 0
    local col = parent.col or 0

    child:SetPos(
        col * (layout.unitw or 200) + (layout.marginw or 0),
        row * (layout.unith or 50) + (layout.marginh or 0)
    )

    row = row + 1
    if row >= layout.rowmax then
        row = 0
        col = col + 1
    end

    parent.row = row
    parent.col = col
end

local function CreateSlider(txt, parent, minv, maxv, decimals)
	local slider = vgui.Create('DNumSlider', parent)
    slider:SetMin(minv or 0)
    slider:SetMax(maxv or 100)
    slider:SetDecimals(decimals or 0)
    slider:SetSize(200, 20)
    slider:SetText(txt)
	return slider
end

local function strdefault(str, default)
	return isstring(str) and str or default
end

local function numdefault(num, default)
	return isnumber(num) and num or default
end

local function UpdateNumCache(wdata)
    local rootcache = wdata.cache or {}
    wdata.cache = rootcache

	local angbound = math.min(
		math.pi * 2 / math.max(#wdata.metadata, 1) * math.max(numdefault(wdata.iconsize, 0.5), 0), 
		math.pi * 0.667
	)

	rootcache.fade = math.max(numdefault(wdata.fade, 100), 0)
	rootcache.centersize = math.max(numdefault(wdata.centersize, 0.5), 0)
	rootcache.iconsize = math.sin(angbound * 0.25) * 2
	rootcache.rotate3d = numdefault(wdata.rotate3d, 10) * math.pi / 180
end

local background = Color(255, 255, 255, 200)
local background2 = Color(150, 150, 150, 200)
local cicondefault = Material('fastcmd/hud/cicon.png')
local arrowdefault = Material('fastcmd/hud/arrow.png')
local icondefault = Material('fastcmd/hud/default.jpg')
local edgedefault = Material('fastcmd/hud/edge.png')
-------------------------
local WheelDataEditor = nil 
local function FcmdOpenWheelDataEditor(filename)
	if IsValid(WheelDataEditor) then WheelDataEditor:Remove() end

	local wdata = FcmdLoadWheelData(filename)
	if not istable(wdata) then return end

	-- 编辑器窗口定义
	WheelDataEditor = vgui.Create('DFrame')
	WheelDataEditor:SetTitle(language.GetPhrase('#fcmdu.title.editor')..' - '..filename)

	WheelDataEditor:SetSize(900, 600)
    WheelDataEditor:SetPos(10, 10)
	WheelDataEditor:SetSizable(true)
	WheelDataEditor:MakePopup()
	WheelDataEditor:SetDeleteOnClose(true)

	function WheelDataEditor:OnRemove()
        if istable(wdata) then
            FcmdSaveWheelData(wdata, filename, true)
            if GetConVar('cl_fcmd_wfile'):GetString() == filename then
                FcmdmReloadCurWData()
            end
        end
	end

	-- 预览与编辑器主体定义
	local ViewPort = vgui.Create('DPanel', WheelDataEditor)
	local Main = vgui.Create('DPanel', WheelDataEditor)
	local div = vgui.Create('DHorizontalDivider', WheelDataEditor)
	
	div:Dock(FILL)
	div:SetLeft(ViewPort)
	div:SetRight(Main)
	div:SetDividerWidth(4)
	div:SetLeftMin(20) 
	div:SetRightMin(20)
	div:SetLeftWidth(250)

    
	function ViewPort:Paint(w, h)
		draw.RoundedBox(5, 0, 0, w, h, background)
		if istable(wdata) then
			local succ = SafeDrawDrawWheel2D(
				self.size, 
				wdata, 
				self.previewtrans
			)
			if not succ then 
                wdata = nil 
            end
		end
	end

	function ViewPort:OnSizeChanged(newWidth, newHeight)
		self.previewtrans = {
            x = 0,
            y = 0,
			w = newWidth,
			h = newHeight,
		}
		self.size = min(newWidth, newHeight) * 0.5
	end

	-- 根属性编辑器与节点属性编辑器定义
	local RootAttrs = vgui.Create('DPanel', Main)
	local MetadataAttrs = vgui.Create('DPanel', Main)

	local div2 = vgui.Create('DVerticalDivider', Main)
	
	div2:Dock(FILL)
	div2:SetTop(RootAttrs)
	div2:SetBottom(MetadataAttrs)
	div2:SetDividerHeight(4)
	div2:SetTopMin(20) 
	div2:SetBottomMin(20)
	div2:SetTopHeight(150)

    Main.Paint = function() end

    -- 根属性编辑器部分
    local RootAttrsLayout = {
        rowmax = 3,
        unitw = 200,
        unith = 40,
        marginw = 10,
        marginh = 10,
    }

    RootAttrs.Paint = function(self, w, h)
        draw.RoundedBox(5, 0, 0, w, h, background2)
    end


	local ciconinput = FcmdCreateMaterialInput('#fcmdu.cicon', RootAttrs)
	local arrow = FcmdCreateMaterialInput('#fcmdu.arrow', RootAttrs)
	local edge = FcmdCreateMaterialInput('#fcmdu.edge', RootAttrs)
	local rotate3d = CreateSlider('#fcmdu.rotate3d', RootAttrs, 0, 180, 0)
	local centersize = CreateSlider('#fcmdu.centersize', RootAttrs, 0, 1, 3)
	local iconsize = CreateSlider('#fcmdu.iconsize', RootAttrs, 0, 1, 3)
	local fade = CreateSlider('#fcmdu.fade', RootAttrs, 0, 255, 0)
    local autoclip = vgui.Create('DButton', RootAttrs)
    autoclip:SetText('#fcmdu.autoclip')
    
    AddItem(RootAttrs, ciconinput, RootAttrsLayout)
    AddItem(RootAttrs, arrow, RootAttrsLayout)
    AddItem(RootAttrs, edge, RootAttrsLayout)
    AddItem(RootAttrs, rotate3d, RootAttrsLayout)
    AddItem(RootAttrs, centersize, RootAttrsLayout)
    AddItem(RootAttrs, iconsize, RootAttrsLayout)
    AddItem(RootAttrs, fade, RootAttrsLayout)
    AddItem(RootAttrs, autoclip, RootAttrsLayout)

    ciconinput:SetValue(strdefault(wdata.cicon, ''))
    arrow:SetValue(strdefault(wdata.arrow, ''))
    edge:SetValue(strdefault(wdata.edge, ''))
    rotate3d:SetValue(numdefault(wdata.rotate3d, 10))
    centersize:SetValue(numdefault(wdata.centersize, 0.5))
    iconsize:SetValue(numdefault(wdata.iconsize, 0.25))
    fade:SetValue(numdefault(wdata.fade, 100))

    function ciconinput:OnValueChange(value)
        // wdata.cache = wdata.cache or {}
        wdata.cicon = value
        wdata.cache.cicon = FcmdLoadMaterials(value, cicondefault)
    end

    function arrow:OnValueChange(value)
        wdata.arrow = value
        wdata.cache.arrow = FcmdLoadMaterials(value, arrowdefault)
    end

    function edge:OnValueChange(value)
        wdata.edge = value
        wdata.cache.edge = FcmdLoadMaterials(value, edgedefault)
    end

    function rotate3d:OnValueChanged(value)
        wdata.rotate3d = value
        UpdateNumCache(wdata)
    end

    function centersize:OnValueChanged(value)
        wdata.centersize = value
        UpdateNumCache(wdata)
    end

    function iconsize:OnValueChanged(value)
        wdata.iconsize = value
        UpdateNumCache(wdata)
    end

    function fade:OnValueChanged(value)
        wdata.fade = value
        UpdateNumCache(wdata)
    end
end

// FcmdOpenWheelDataEditor('fastcmd/wheel/chat.json')
concommand.Add('fcmdu_open_editor', function(ply, cmd, args)
    local filename = args[1] or 'fastcmd/wheel/chat.json'
	FcmdOpenWheelDataEditor(filename)
end)

