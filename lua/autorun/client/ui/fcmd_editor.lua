min, max = math.min, math.max

include('../core/fcmd_wheel.lua') 
local DrawWheel2D = FcmdDrawWheel2D

local function SafeDrawDrawWheel2D(size, wdata, preview)
    local succ, err = pcall(DrawWheel2D, size, wdata, 1, preview)
	if not succ then
		render.ClearStencil()
		render.SetStencilEnable(false)
		render.OverrideColorWriteEnable(false)

        
		ErrorNoHaltWithStack(err)
        FcmdError('#fcmdu.err.fatal', '#fcmdu.err.data')
	end
	return succ
end
-------------------------
local WheelDataEditor = nil 
local function FcmdOpenWheelDataEditor(filename)
	if IsValid(WheelDataEditor) then WheelDataEditor:Remove() end

	local wdata = FcmdLoadWheelData(filename)
	if not istable(wdata) then return end

	local scrw, scrh = ScrW(), ScrH()

	-- 编辑器窗口定义
	WheelDataEditor = vgui.Create('DFrame')
	WheelDataEditor:SetTitle('#fcmdu.title.editor')
	WheelDataEditor:SetSize(scrw * 0.6, scrh * 0.7)
	WheelDataEditor:Center()
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
	
    local background = Color(255, 255, 255, 200)
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

	-- 根属性编辑器部分
	local ciconinput = FcmdCreateMaterialInput('#fcmdu.cicon', RootAttrs)
    ciconinput:SetHeight(30)
    ciconinput:Dock(TOP)
	// local arrow = CreateMaterialInput(RootAttrs)
	// local edge = CreateMaterialInput(RootAttrs)
	// local transform3dbtn = vgui.Create('DButton', RootAttrs)
	// local autoclip = vgui.Create('DButton', RootAttrs)
	// local centersize = vgui.Create('DSlider', RootAttrs)
	// local iconsize = vgui.Create('DSlider', RootAttrs)
	// local fade = vgui.Create('DSlider', RootAttrs)
end
FcmdOpenWheelDataEditor('fastcmd/wheel/chat.json')

