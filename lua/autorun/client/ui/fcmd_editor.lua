min, max = math.min, math.max
surface = surface
include('../core/fcmd_wheel.lua') 
local DrawWheel2D = FcmdDrawWheel2D
local DrawBounds = FcmdDrawBounds
-------------------------
local background = Color(255, 255, 255, 100)
local background2 = Color(100, 100, 100, 200)
local textcolor = Color(0, 0, 0, 255)
local cicondefault = Material('fastcmd/hud/cicon.png')
local arrowdefault = Material('fastcmd/hud/arrow.png')
local icondefault = Material('fastcmd/hud/default.jpg')
local edgedefault = Material('fastcmd/hud/edge.png')

local function shallowcopy(tbl)
	local result = {}
	for i, v in pairs(tbl) do 
		result[i] = v 
	end
	return result
end

local function SetMaterial(mat)
	if istable(mat) then
		-- 处理异步材质
		surface.SetMaterial(mat.mat)
	else
		surface.SetMaterial(mat)
	end
end

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
    -- 用于更新高耦合的参数
    local metadata = wdata.metadata
    local rootcache = wdata.cache

	local angbound = math.min(
		math.pi * 2 / math.max(#metadata, 1) * math.max(numdefault(wdata.iconsize, 0.5), 0), 
		math.pi * 0.667
	)

    rootcache.angbound = angbound
	rootcache.fade = math.max(numdefault(wdata.fade, 100), 0)
	rootcache.centersize = math.max(numdefault(wdata.centersize, 0.5), 0)
	rootcache.iconsize = math.sin(angbound * 0.25) * 2
	rootcache.rotate3d = numdefault(wdata.rotate3d, 10) * math.pi / 180
end

local function UpdateNodeNumCache(wdata)
    -- 用于更新高耦合的参数
    -- 主要更新图标位置
    local metadata = wdata.metadata
	local step = math.pi * 2 / #metadata
	for i, node in ipairs(metadata) do 
		local ang = -0.5 * math.pi + (i - 1) * step
        local nodecache = istable(node.cache) and node.cache or {}
		nodecache.dir = Vector(math.cos(ang), math.sin(ang), 0)
        nodecache.addlen = 0
        node.cache = nodecache
	end
end

local clipboard

local function CreateNodeEditor(node)
    -- 希望DListLayout能正确管理子控件
    if not istable(node) then return end
    node.call = istable(node.call) and node.call or {}
    node.cache = istable(node.cache) and node.cache or {icon = FcmdLoadMaterials(node.icon, icondefault)}

    local Body = vgui.Create('DPanel')
    local preview = vgui.Create('DPanel', Body)
    local iconinput = FcmduCreateMaterialInput('', Body)
    local CmdCategory = vgui.Create('DCollapsibleCategory', Body)
    
    Body:SetTall(64)
    Body.node = node

    preview:SetSize(64, 64)
    preview:SetPos(0, 0)

    iconinput.layout = {0, 0.7, 0.3}
    iconinput:SetSize(200, 20)
    iconinput:SetPos(64, 22)

    CmdCategory:SetLabel('#fcmdu.cmd')
    CmdCategory:SetExpanded(false)
    CmdCategory:SetSize(200, 20)
    CmdCategory:SetPos(284, 22)

    function preview:Paint(nw, nh)
        if node.cache.icon then   
            surface.SetDrawColor(255, 255, 255, 255)
            SetMaterial(node.cache.icon)
            surface.DrawTexturedRect(0, 0, nw, nh)      
        end
    end

    function Body:OnSizeChanged(nw, nh)
        CmdCategory:SetWide(math.max(nw - 304, 64))
    end

    function CmdCategory:OnToggle(expand)
        if expand then
            Body:SetTall(150)
        else
            Body:SetTall(64)
        end
    end

    // ----
    local CmdContent = FcmduCreateCustomGrid(
        CmdCategory,
        {
            row = 10,
            col = 1,
            paddingw = 10,
            h = 20
        }
    )
    CmdContent:Dock(FILL)
    local pexecuteinput = FcmduCmdInput('#fcmdu.pexecute', CmdContent)
	local rexecuteinput = FcmduCmdInput2('#fcmdu.rexecute', CmdContent, pexecuteinput)
    local bexecuteinput = FcmduCmdInput2('#fcmdu.bexecute', CmdContent, pexecuteinput)
    local sexecuteinput = FcmduCmdInput('#fcmdu.sexecute', CmdContent)
    
    CmdContent:AddItem(pexecuteinput)
    CmdContent:AddItem(rexecuteinput)
    CmdContent:AddItem(bexecuteinput)
    CmdContent:AddItem(sexecuteinput)

    CmdCategory:SetContents(CmdContent)

    function Body:Paint(w, h)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawLine(0, h - 1, w, h - 1)
    end

    iconinput:SetUpdateOnType(false)
    iconinput:SetValue(strdefault(node.icon, ''))
    function iconinput:OnValueChange(value)
        node.icon = value
        node.cache.icon = FcmdLoadMaterials(value, icondefault)
    end


    pexecuteinput:SetValue(strdefault(node.call.pexecute, ''))
    function pexecuteinput:OnValueChange(value)
        node.call.pexecute = value
    end

    rexecuteinput:SetValue(node.call.rexecute)
    function rexecuteinput:OnValueChange(value)
        node.call.rexecute = value
    end

    bexecuteinput:SetValue(node.call.bexecute)
    function bexecuteinput:OnValueChange(value)
        node.call.bexecute = value
    end

    sexecuteinput:SetValue(strdefault(node.call.sexecute, ''))
    function sexecuteinput:OnValueChange(value)
        node.call.sexecute = value
    end


    local DragCall = Body.OnMousePressed
    function Body:OnMousePressed(keyCode)
        DragCall(Body, keyCode)
        if keyCode == MOUSE_RIGHT then
            local menu = DermaMenu() 

            local copy = menu:AddOption('#fcmdu.copy', function()
                local copynode = shallowcopy(node)
                copynode.cache = nil 
                clipboard = util.TableToJSON(copynode)

                if not isstring(clipboard) then return end
                local parent = self:GetParent()
                if IsValid(parent) then
                    local newnode = util.JSONToTable(clipboard)
                    if istable(newnode) then parent:Add(CreateNodeEditor(newnode)) end
                    parent:Save()
                end
            end)
            copy:SetImage('materials/icon16/application_double.png')

            local delete = menu:AddOption('#fcmdu.delete', function()
                self.node = nil
                self:Remove()

                local parent = self:GetParent()
                if IsValid(parent) then
                    parent:Save()
                end
            end)
            delete:SetImage('materials/icon16/application_delete.png')

            menu:Open()
        end

    end

    return Body
end
-------------------------
local Opened = {}
function FcmdOpenWheelDataEditor(filename)
    if IsValid(Opened[filename]) then 
        Opened[filename]:SetVisible(true)
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
    WheelDataEditor:SetDeleteOnClose(false)

    function WheelDataEditor:Save()
        if istable(wdata) then
            FcmdSaveWheelData(wdata, filename, true)
            if GetConVar('cl_fcmdm_wfile'):GetString() == filename then
                FcmdmReloadCurWData()
            end
        end
    end

    function WheelDataEditor:OnClose()
        self:Save()
    end

	function WheelDataEditor:OnRemove()
        self:Save()
        Opened[filename] = nil
	end

	-- 预览与编辑器主体定义
	local ViewPort = vgui.Create('DPanel', WheelDataEditor)
	local Main = vgui.Create('DScrollPanel', WheelDataEditor)
	local div = vgui.Create('DHorizontalDivider', WheelDataEditor)
    local SaveBtn = vgui.Create('DButton', WheelDataEditor)
    
    SaveBtn:SetText('#fcmdu.save_and_remove')
    SaveBtn:SetTall(50)
	SaveBtn:Dock(BOTTOM)
    SaveBtn:DockMargin(0, 10, 0, 10)
	div:Dock(FILL)
	div:SetLeft(ViewPort)
	div:SetRight(Main)
	div:SetDividerWidth(4)
	div:SetLeftMin(20) 
	div:SetRightMin(20)
	div:SetLeftWidth(250)

    function SaveBtn:DoClick()
        WheelDataEditor:Save()
        WheelDataEditor:Remove()
    end


	function ViewPort:Paint(w, h)
		draw.RoundedBox(5, 0, 0, w, h, background)
        // PrintTable(wdata)
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

    local VisualContent = FcmduCreateCustomGrid(
        VisualCategory, 
        {
            row = 3,
            col = 3,
            paddingw = 10,
            h = 20
        }
    )
    VisualContent:Dock(FILL)

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
    SoundCategory:SetExpanded(false)
    SoundCategory:Dock(TOP)

    local SoundContent = FcmduCreateCustomGrid(
        SoundCategory, 
        {
            row = 3,
            col = 3,
            paddingw = 10,
            h = 20
        }
    )
    SoundContent:Dock(FILL)

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

    loadsound:SetValue(strdefault(wdata.loadsound, ''))
    function loadsound:OnValueChange(val)
        wdata.loadsound = val
    end

    soundexpand:SetValue(strdefault(wdata.soundexpand, ''))
    function soundexpand:OnValueChange(val)
        wdata.soundexpand = val
    end

    soundclose:SetValue(strdefault(wdata.soundclose, ''))
    function soundclose:OnValueChange(val)
        wdata.soundclose = val
    end

    soundgiveup:SetValue(strdefault(wdata.soundgiveup, ''))
    function soundgiveup:OnValueChange(val)
        wdata.soundgiveup = val
    end

    soundselect:SetValue(strdefault(wdata.soundselect, ''))
    function soundselect:OnValueChange(val)
        wdata.soundselect = val
    end


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
        local graph = CreateNodeEditor(node)
        if graph then
            MetadataContent:Add(graph)
        end
    end

    function MetadataContent:Save()
        local children = self:GetChildren()
        wdata.metadata = {}
        for _, child in ipairs(children) do
            if istable(child.node) then
                table.insert(wdata.metadata, child.node)
            end
        end
        UpdateNodeNumCache(wdata)
    end

    function MetadataContent:OnModified()
        self:Save()
    end

    function Main:OnMousePressed(keyCode)
        if keyCode == MOUSE_RIGHT then
            local menu = DermaMenu() 

            local create = menu:AddOption('#fcmdu.create', function()
                MetadataContent:Add(CreateNodeEditor({}))
                MetadataContent:Save()
            end)
            create:SetImage('icon16/application_add.png')

            local paste = menu:AddOption('#fcmdu.paste', function()
                if not isstring(clipboard) then return end
                local newnode = util.JSONToTable(clipboard)
                if istable(newnode) then MetadataContent:Add(CreateNodeEditor(newnode)) end
                MetadataContent:Save()
            end)
            paste:SetImage('materials/icon16/application_double.png')

            menu:Open()
        end
    end

    MetadataCategory:SetContents(MetadataContent)

    ciconinput:SetValue(strdefault(wdata.cicon, ''))
    arrow:SetValue(strdefault(wdata.arrow, ''))
    edge:SetValue(strdefault(wdata.edge, ''))
    rotate3d:SetValue(numdefault(wdata.rotate3d, 10))
    centersize:SetValue(numdefault(wdata.centersize, 0.5))
    iconsize:SetValue(numdefault(wdata.iconsize, 0.25))
    fade:SetValue(numdefault(wdata.fade, 100))
    autoclip:SetState(wdata.autoclip)

    function ciconinput:OnValueChange(value)
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

    function autoclip:Trigger(state)
        wdata.autoclip = state
    end

    ----
    return WheelDataEditor
end
// FcmdOpenWheelDataEditor('fastcmd/wheel/chat.json')

concommand.Add('fcmdu_open_editor', function(ply, cmd, args)
    local filename = args[1] or 'fastcmd/wheel/chat.json'
	FcmdOpenWheelDataEditor(filename)
end)
