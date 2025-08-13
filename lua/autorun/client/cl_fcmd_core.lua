local ScrW, ScrH = ScrW, ScrH
local gui = gui
local sqrt = math.sqrt
local cos, sin, atan2 = math.cos, math.sin, math.atan2
local max, min, Clamp = math.max, math.min, math.Clamp
local pi, halfpi, twopi, ang_120 = math.pi, math.pi * 0.5, math.pi * 2, math.pi / 1.5
local radunit = 180 / math.pi
local surface = surface
local RealFrameTime = RealFrameTime
local Vector = Vector

local cicondefault = Material('hud/fastcmd/cicon.png')
local arrowdefault = Material('hud/fastcmd/arrow.png')
local icondefault = Material('hud/fastcmd/default.png')
local circlemask = Material('hud/fastcmd/circlemask')
local edge = Material('hud/fastcmd/edge.png')
local edgecolordefault = {r = 255, g = 255, b = 255, a = 255}
local transform3ddefault = {enable = true, ang = 10, depth = 700}


local function trim(str) 
	return str:gsub('^%s+', ''):gsub('%s+$', '') 
end

local function Elasticity(x)
	if x >= 1 then return 1 end
	return x * 1.4301676 + math.sin(x * 4.0212386) * 0.55866
end

function fcmd_ErrorNoHalt(text)
	notification.AddLegacy(text, NOTIFY_ERROR, 5)
	surface.PlaySound('Buttons.snd10')
end

function fcmd_Warning(text)
	notification.AddLegacy(text, NOTIFY_GENERIC, 5)
	surface.PlaySound('Buttons.snd8')
end

local FastError = fcmd_ErrorNoHalt
local FastWarning = fcmd_Warning


function fcmd_DrawHud2D(size, fcmddata, state, debug)
	-- 绘制 HUD
	-- size 菜单尺寸 (直径)
	-- fcmddata 指令数据
	-- state 尺寸插值比例
	state = max(state, 0)

	local w, h = ScrW(), ScrH()
	local cx, cy = w * 0.5, h * 0.5
	local x, y = gui.MouseX(), gui.MouseY()
	local stateinterp = Elasticity(state)
	 
	-- 使用插值后的大小, 图标大小使用等分占比
	size = max(size, 0) * stateinterp
	local rootcache = fcmddata.cache
	local iconsize = rootcache.iconsize * size
	local centersize = rootcache.centersize * size
	local fade = rootcache.fade * state

	draw.NoTexture()
	-- 淡入黑色背景
	surface.SetDrawColor(0, 0, 0, fade)
	surface.DrawRect(0, 0, w, h)
	
	-- 中心图标绘制
	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(rootcache.cicon)
	surface.DrawTexturedRectRotated(cx, cy, centersize, centersize, 0)

	-- 箭头图标绘制
	if rootcache.selectIdx ~= nil then
		local mouseang = (atan2(y - cy, x - cx) + halfpi) * radunit
		surface.SetMaterial(rootcache.arrow)
		surface.DrawTexturedRectRotated(cx, cy, centersize, centersize, -mouseang)
	end

	---- 指令图标绘制
	-- 自动圆形裁剪
	if fcmddata.autoclip then 
		render.ClearStencil()
		render.SetStencilEnable(true)
		render.SetStencilWriteMask(255)
		render.SetStencilTestMask(255)
		render.SetStencilFailOperation(STENCIL_KEEP)
		render.SetStencilZFailOperation(STENCIL_REPLACE)
		render.SetStencilPassOperation(STENCIL_REPLACE)
		render.SetStencilCompareFunction(STENCIL_ALWAYS)
		render.SetStencilReferenceValue(1)

		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(circlemask)

		render.OverrideColorWriteEnable(true, false)
		for i, data in ipairs(fcmddata.metadata) do	 
			local cache = data.cache
			local lpos = size * cache.dir * (0.5 + cache.addlen * 0.1)

			surface.DrawTexturedRectRotated(
				cx + lpos.x, 
				cy + lpos.y, 
				iconsize, iconsize, 0)
		end
		render.OverrideColorWriteEnable(false)
		
		render.SetStencilCompareFunction(STENCIL_EQUAL)
	end


	for i, data in ipairs(fcmddata.metadata) do	 
		local cache = data.cache
		-- 为选择的图标添加附加距离
		if rootcache.selectIdx == i then
			cache.addlen = Clamp(cache.addlen + 10 * RealFrameTime(), 0, 1)
			surface.SetDrawColor(255, 255, 255)
		else
			cache.addlen = Clamp(cache.addlen - 10 * RealFrameTime(), 0, 1)
			surface.SetDrawColor(150, 150, 150)
		end
		local lpos = size * cache.dir * (0.5 + cache.addlen * 0.1)

		surface.SetMaterial(cache.icon)
		surface.DrawTexturedRectRotated(cx + lpos.x, cy + lpos.y, iconsize, iconsize, 0)
	end

	-- 绘制边缘
	if fcmddata.autoclip then 
		local color = rootcache.edgecolor
		render.SetStencilEnable(false)
		surface.SetDrawColor(color.r, color.g, color.b, color.a)
		surface.SetMaterial(edge)

		for i, data in ipairs(fcmddata.metadata) do	 
			local cache = data.cache
			local lpos = size * cache.dir * (0.5 + cache.addlen * 0.1)

			surface.DrawTexturedRectRotated(
				cx + lpos.x, 
				cy + lpos.y, 
				iconsize, iconsize, 0)
		end
	end

	if debug then
		surface.DrawCircle(cx, cy, size * 0.5, 255, 255, 255, 255)
		surface.DrawCircle(cx, cy, centersize * 0.5, 255, 255, 255, 255)
		for i, data in ipairs(fcmddata.metadata) do	 
			local cache = data.cache
			cache.addlen = rootcache.selectIdx == i and 1 or 0
			local lpos = size * cache.dir * (0.5 + cache.addlen * 0.1)
			surface.DrawCircle(cx + lpos.x, cy + lpos.y, iconsize * 0.5, 255, 255, 255, 255)
		end
	end
end

function fcmd_CheckSelect(size, fcmddata)
	-- 检查选中
	-- 检查直径
	local w, h = ScrW(), ScrH()
	local cx, cy = w * 0.5, h * 0.5
	local dx, dy = gui.MouseX() - cx, gui.MouseY() - cy
	if dx * dx + dy * dy < size * size * 0.25 then return nil end -- 距离判断
	local mousedir = Vector(dx, dy, 0)

	-- 使用叉积计算碰撞
	local rootcache = fcmddata.cache
	for i, data in ipairs(fcmddata.metadata) do
		local bounds = data.cache.bounds
		local crossleft, crossright = mousedir:Cross(bounds[1]).z, mousedir:Cross(bounds[2]).z
		if crossleft < 0 and crossright > 0 then
			return i
		end
	end

	return 0
end

function fcmd_LoadsFcmdData(json)
	-- 加载数据并验证
	local fcmddata = util.JSONToTable(json)
	if not istable(fcmddata) then 
		FastError('#fcmd.err.loads.not_json')
		return nil
	else
		-- 自动修复metadata
		if not istable(fcmddata.metadata) then
			FastWarning('#fcmd.warn.loads.loss_metadata')
			fcmddata.metadata = {}
		end
	end

	---- 计算缓存
	local rootcache = {
		selectIdx = nil, -- 选中的索引
	}
	fcmddata.cache = rootcache

	-- 加载图标材质
	if isstring(fcmddata.cicon) and fcmddata.cicon ~= '' then
		rootcache.cicon = Material(fcmddata.cicon)
	else
		rootcache.cicon = cicondefault
	end
	if isstring(fcmddata.arrow) and fcmddata.arrow ~= '' then
		rootcache.arrow = Material(fcmddata.arrow)
	else
		rootcache.arrow = arrowdefault
	end

	---- 变量边界

	-- 比例、角度边界大小
	local angbound = min(
		twopi / #fcmddata.metadata * max(fcmddata.iconsize or 0.5, 0), 
		ang_120
	)

	rootcache.fade = max(fcmddata.fade or 100, 0)
	rootcache.centersize = max(fcmddata.centersize or 0.5, 0)
	rootcache.iconsize = sin(angbound * 0.25) * 2

	-- 边缘颜色参数
	rootcache.edgecolor = istable(fcmddata.edgecolor) and fcmddata.edgecolor or edgecolordefault
	rootcache.edgecolor.r = Clamp(rootcache.edgecolor.r or 0, 0, 255) 
	rootcache.edgecolor.g = Clamp(rootcache.edgecolor.g or 0, 0, 255) 
	rootcache.edgecolor.b = Clamp(rootcache.edgecolor.b or 0, 0, 255) 
	rootcache.edgecolor.a = Clamp(rootcache.edgecolor.a or 255, 0, 255) 

	-- 3D变换参数
	rootcache.transform3d = istable(fcmddata['3dtransform']) and fcmddata['3dtransform'] or transform3ddefault
	rootcache.transform3d.ang = rootcache.transform3d.ang or 10
	rootcache.transform3d.depth = rootcache.transform3d.depth or 700

	-- 生成位置、加载材质
	local step = twopi / #fcmddata.metadata
	for i, data in pairs(fcmddata.metadata) do 
		if not isnumber(variable) then
			FastWarning('#fcmd.warn.loads.invalid_idx')
			continue
		end

		local ang = -halfpi + (i - 1) * step
		local angleft = ang - 0.5 * angbound
		local angright = ang + 0.5 * angbound

		local nodecache = {
			dir = Vector(cos(ang), sin(ang), 0),
			addlen = 0,
			bounds = {
				Vector(cos(angleft), sin(angleft), 0),
				Vector(cos(angright), sin(angright), 0),
			}
		}

		local icon = data.icon
		if isstring(icon) and icon ~= '' then
			nodecache.icon = Material(icon)
		else
			nodecache.icon = icondefault
		end

		data.cache = nodecache
	end

	return fcmddata
end

function fcmd_DumpsFcmdData(fcmddata)
	-- 序列化数据
	if not istable(fcmddata) then
		FastError('#fcmd.err.dumps.not_table')
		return nil
	end

	fcmddata.cache = nil
	if istable(fcmddata.metadata) then
		for _, data in pairs(fcmddata.metadata) do
			data.cache = nil
		end
	end

	return util.TableToJSON(fcmddata, true)
end

function fcmd_LoadFcmdDataFromFile(filename)
	-- 从文件中获取fcmddata

	-- 是否为字符串
	if not isstring(filename) then  
		FastError('#fcmd.err.file.not_string')
		return nil
	end

	filename = trim(filename)
	local root = 'fastcmd'
	local path = root..'/'..filename..'.json'
	-- 存在性、格式过滤等
	if filename == '' or filename == '0' then
		-- 在设计中, 切换玩家当前的fcmddata依赖参数变化的函数, 所以重载前需要先清空
		-- 所以这里不视为错误
		return nil
	elseif not file.Exists(path, 'DATA') then
		FastError('#fcmd.err.file.not_exist')
		return nil
	end

	local json = file.Read(path, 'DATA')	
	return fcmd_LoadsFcmdData(json)
end

function fcmd_SaveFcmdDataToFile(fcmddata, filename, override)
	-- 保存fcmddata文件

	-- 是否为字符串
	if not isstring(filename) then  
		FastError('#fcmd.err.save.not_string')
		return false
	end

	filename = trim(filename)
	local root = 'fastcmd'
	local path = root..'/'..filename..'.json'

	-- 存在性、格式过滤等
	if filename == '' or filename == '0' then
		FastError('#fcmd.err.save.empty')
		return false
	elseif not override and file.Exists(path, 'DATA') then
		FastError('#fcmd.err.save.exist')
		return false
	end

	local json = fcmd_DumpsFcmdData(fcmddata)
	file.Write(path, json)

	return true
end

function fcmd_CmdFilter(cmd)
	-- 过滤含有fcmd_的指令, 防止无限递归
	local result = {}

    -- 以;分割所有子串
    for part in string.gmatch(cmd, '([^;]+)') do
        if not string.find(part, 'fcmd_') then
            table.insert(result, part)
        end
    end

    return table.concat(result, ';')
end

function fcmd_AutoParseRExecute(cmd)
    -- 自动解析释放指令：保留含+的子串，并将所有+替换为-
    local result = {}

    -- 以;分割所有子串
    for part in string.gmatch(cmd, '([^;]+)') do
        -- 条件：包含+
        if string.find(part, '%+') then
            -- 将子串中的所有+替换为-
            local replacedPart = string.gsub(part, '%+', '-')
            table.insert(result, replacedPart)
        end
    end
    return table.concat(result, ';')
end

local CmdFilter = fcmd_CmdFilter
local AutoParseRExecute = fcmd_AutoParseRExecute
function fcmd_Execute(call, press)
	-- 执行指令
	// PrintTable(call)
	if press then
		if isstring(call.pexecute) then
			LocalPlayer():ConCommand(CmdFilter(call.pexecute))
			// print('pexecute', CmdFilter(call.pexecute))
		end
	else
		if isstring(call.rexecute) then
			LocalPlayer():ConCommand(CmdFilter(call.rexecute))
			// print('rexecute', CmdFilter(call.rexecute))
		elseif isstring(call.pexecute) then
			LocalPlayer():ConCommand(CmdFilter(AutoParseRExecute(call.pexecute)))
			// print('autopexecute', CmdFilter(AutoParseRExecute(call.pexecute)))
		end
	end
end

function fcmd_Break(cmd)
	-- 执行中断指令
	// print('fcmd_Break', cmd)
	if not isstring(cmd) then return end
	LocalPlayer():ConCommand(CmdFilter(cmd))
end

local DrawHud2D = fcmd_DrawHud2D
local startmartix = Matrix()
	startmartix:SetTranslation(Vector())
	startmartix:SetAngles(Angle(90, 0, -90))
local zerovec, zeroang = Vector(), Angle()
function fcmd_DrawHud(size, fcmddata, state, debug)
	-- 绘制 HUD
	local rootcache = fcmddata.cache 
	local transform3d = rootcache.transform3d
	if transform3d.enable then
		state = max(state, 0)
		local w, h = ScrW(), ScrH()
		local cx, cy = w * 0.5, h * 0.5
		
		local ang, depth = transform3d.ang / radunit, transform3d.depth
		-- 计算变换矩阵
		-- 这个Start3D2D用不明白, 只能用两次旋转合成了
		local cammartix
		if rootcache.selectIdx ~= nil then
			local dx, dy = gui.MouseX() - cx, gui.MouseY() - cy
			local dis = math.sqrt(dx * dx + dy * dy)
			local sina, cosa = sin(ang), cos(ang)
			local pitch = math.atan2(dx / dis * sina, cosa) * radunit
			local roll = math.asin(dy / dis * sina) * radunit
			local rotate = Matrix()
			rotate:SetAngles(Angle(pitch, 0, roll))
			cammartix = rotate * startmartix
		else
			cammartix = startmartix
		end
		local campos, camang = Vector(cx, -cy, 0) - cammartix:GetForward() * depth, cammartix:GetAngles()

		
		local fade = rootcache.fade

		draw.NoTexture()
		-- 淡入黑色背景
		surface.SetDrawColor(0, 0, 0, fade * state)
		surface.DrawRect(0, 0, w, h)

		local old = DisableClipping(true)
		rootcache.fade = 0 -- 禁用2D的淡入绘制
		
		cam.Start3D(campos, camang)
			cam.Start3D2D(zerovec, zeroang, 1)
				DrawHud2D(size, fcmddata, state, debug)
			cam.End3D2D() 
		cam.End3D()

		rootcache.fade = fade -- 恢复数据
		DisableClipping(old)
	else
		DrawHud2D(size, fcmddata, state, debug)
	end
end
