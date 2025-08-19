min, max = math.min, math.max
include('../core/fcmd_wheel.lua') 
local DrawWheel2D = FcmdDrawWheel2D
local DrawBounds = FcmdDrawBounds
-------------------------
local background = Color(255, 255, 255, 200)
local background2 = Color(100, 100, 100, 200)
local cicondefault = Material('fastcmd/hud/cicon.png')
local arrowdefault = Material('fastcmd/hud/arrow.png')
local icondefault = Material('fastcmd/hud/default.jpg')
local edgedefault = Material('fastcmd/hud/edge.png')

local function SafeDrawWheel2D(size, wdata, preview)
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

local function CreateNodeEditor(node, parent)
    // if not istable(node) then return end
 
    // local Body = FcmduCreateCustomGrid(parent)
    // Body:SetLayout(2, 2, 20, 10, 20)
    // Body:SetSize(200, 200)

    // local iconinput = FcmduCreateMaterialInput('#fcmdu.icon', Body)
    // local pexecuteinput = CreateTextEntry('#fcmdu.pexecute', Body)
    // local AdvancedCategory = vgui.Create('DCollapsibleCategory', Body)
    // AdvancedCategory:SetLabel('#fcmdu.advanced')
    // AdvancedCategory:SetExpanded(false)

    // Body:AddItem(iconinput)
    // Body:AddItem(pexecuteinput)
    // Body:AddItem(AdvancedCategory)
    
     

    // local AdvancedContent = FcmduCreateCustomGrid(AdvancedCategory)
    // AdvancedContent:Dock(FILL)
    // AdvancedContent:SetLayout(9999, 1, 20, 10, 20)

	// local rexecute = FcmduCreateMaterialInput('#fcmdu.cicon', AdvancedContent)
    // AdvancedContent:AddItem(ciconinput)


    // VisualCategory:SetContents(VisualContent)

    // iconinput:SetValue(node.icon)
    // function iconinput:OnValueChange(value)
    //     // wdata.cache = wdata.cache or {}
    //     node.icon = value
    //     node.cache.icon = FcmdLoadMaterials(value, icondefault)
    // end

    // function Body:Paint(w, h)
    //     surface.SetDrawColor(255, 255, 255, 0)
    //     surface.DrawLine(0, 0, w, h)
    // end

    return Body
end

local function UpdateNodeCache(wdata)

end
-------------------------
local Opened = {}
function FcmdOpenWheelDataEditor(filename)
    if IsValid(Opened[filename]) then 
        local WheelDataEditor = Opened[filename]
        WheelDataEditor:SetPos(10, 10)
        WheelDataEditor:SetVisible(true)
        return 
    end

	local wdata = FcmdLoadWheelData(filename)
	if not istable(wdata) then return end

	-- 编辑器窗口定义
    Opened[filename] = vgui.Create('DFrame')
    local WheelDataEditor = Opened[filename]
	WheelDataEditor:SetTitle(language.GetPhrase('#fcmdu.title.editor')..' - '..filename)

	WheelDataEditor:SetSize(1000, 600)
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

        Opened[filename] = nil
	end

	-- 预览与编辑器主体定义
	local ViewPort = vgui.Create('DPanel', WheelDataEditor)
	local Main = vgui.Create('DScrollPanel', WheelDataEditor)
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
			local succ = SafeDrawWheel2D(
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


    function Main:Paint() end
    ----
    local VisualCategory = vgui.Create('DCollapsibleCategory', Main)	
    VisualCategory:SetLabel('#fcmdu.visual')
    VisualCategory:SetExpanded(true)
    VisualCategory:Dock(TOP)

    local VisualContent = FcmduCreateCustomGrid(VisualCategory)
    VisualContent:Dock(FILL)
    VisualContent:SetLayout(3, 3, 20, 10, 20)

	local ciconinput = FcmduCreateMaterialInput('#fcmdu.cicon', VisualContent)
	local arrow = FcmduCreateMaterialInput('#fcmdu.arrow', VisualContent)
	local edge = FcmduCreateMaterialInput('#fcmdu.edge', VisualContent)
	local rotate3d = FcmduCreateNumSlider('#fcmdu.rotate3d', VisualContent, 0, 180, 0)
	local centersize = FcmduCreateNumSlider('#fcmdu.centersize', VisualContent, 0, 1, 3)
	local iconsize = FcmduCreateNumSlider('#fcmdu.iconsize', VisualContent, 0, 1, 3)
	local fade = FcmduCreateNumSlider('#fcmdu.fade', VisualContent, 0, 255, 0)
    local autoclip = FcmduCreateBoolenButton('#fcmdu.autoclip', '#fcmdu.noclip', VisualContent)

    VisualContent:AddItem(ciconinput)
    VisualContent:AddItem(arrow)
    VisualContent:AddItem(edge)
    VisualContent:AddItem(rotate3d)
    VisualContent:AddItem(centersize)
    VisualContent:AddItem(iconsize)
    VisualContent:AddItem(fade)
    VisualContent:AddItem(autoclip)

    VisualCategory:SetContents(VisualContent)	
    ----
    local SoundCategory = vgui.Create('DCollapsibleCategory', Main)	
    SoundCategory:SetLabel('#fcmdu.sound')
    SoundCategory:SetExpanded(true)
    SoundCategory:Dock(TOP)

    local SoundContent = FcmduCreateCustomGrid(SoundCategory)
    SoundContent:Dock(FILL)
    SoundContent:SetLayout(3, 3, 20, 10, 20)

	local loadsound = FcmduCreateSoundInput('#fcmdu.loadsound', SoundContent)
    local soundexpand = FcmduCreateSoundInput('#fcmdu.soundexpand', SoundContent)
    local soundclose = FcmduCreateSoundInput('#fcmdu.soundclose', SoundContent)
    local soundgiveup = FcmduCreateSoundInput('#fcmdu.soundgiveup', SoundContent)
    local soundselect = FcmduCreateSoundInput('#fcmdu.soundselect', SoundContent)

    SoundContent:AddItem(loadsound)
    SoundContent:AddItem(soundexpand)
    SoundContent:AddItem(soundclose)
    SoundContent:AddItem(soundgiveup)
    SoundContent:AddItem(soundselect)

    SoundCategory:SetContents(SoundContent)	
    ----
    local MetadataCategory = vgui.Create('DCollapsibleCategory', Main)	
    MetadataCategory:SetLabel('#fcmdu.metadata')
    MetadataCategory:SetExpanded(true)
    MetadataCategory:Dock(TOP)

    local MetadataContent = vgui.Create('DListLayout', MetadataCategory)
    MetadataContent:Dock(FILL)
    MetadataContent:MakeDroppable('fcmdu_wdata_metadata', true)


    for _, node in ipairs(wdata.metadata) do 
        // MetadataContent:Add(CreateNodeEditor(node))
    end

    function MetadataContent:OnModified()
        print('OnModified')
    end

    MetadataCategory:SetContents(MetadataContent)

    // ciconinput:SetValue(strdefault(wdata.cicon, ''))
    // arrow:SetValue(strdefault(wdata.arrow, ''))
    // edge:SetValue(strdefault(wdata.edge, ''))
    // rotate3d:SetValue(numdefault(wdata.rotate3d, 10))
    // centersize:SetValue(numdefault(wdata.centersize, 0.5))
    // iconsize:SetValue(numdefault(wdata.iconsize, 0.25))
    // fade:SetValue(numdefault(wdata.fade, 100))

    // function ciconinput:OnValueChange(value)
    //     // wdata.cache = wdata.cache or {}
    //     wdata.cicon = value
    //     wdata.cache.cicon = FcmdLoadMaterials(value, cicondefault)
    // end

    // function arrow:OnValueChange(value)
    //     wdata.arrow = value
    //     wdata.cache.arrow = FcmdLoadMaterials(value, arrowdefault)
    // end

    // function edge:OnValueChange(value)
    //     wdata.edge = value
    //     wdata.cache.edge = FcmdLoadMaterials(value, edgedefault)
    // end

    // function rotate3d:OnValueChanged(value)
    //     wdata.rotate3d = value
    //     UpdateNumCache(wdata)
    // end

    // function centersize:OnValueChanged(value)
    //     wdata.centersize = value
    //     UpdateNumCache(wdata)
    // end

    // function iconsize:OnValueChanged(value)
    //     wdata.iconsize = value
    //     UpdateNumCache(wdata)
    // end

    // function fade:OnValueChanged(value)
    //     wdata.fade = value
    //     UpdateNumCache(wdata)
    // end

    // function autoclip:DoClick()
    //     wdata.autoclip = not wdata.autoclip
    //     self:SetText(wdata.autoclip and '#fcmdu.autoclip.on' or '#fcmdu.autoclip.off')
    // end

    ----
    return WheelDataEditor
end
FcmdOpenWheelDataEditor('fastcmd/wheel/chat.json')

concommand.Add('fcmdu_open_editor', function(ply, cmd, args)
    local filename = args[1] or 'fastcmd/wheel/chat.json'
	FcmdOpenWheelDataEditor(filename)
end)
