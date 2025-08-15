local ScrW, ScrH = ScrW, ScrH
local gui = gui
local sqrt = math.sqrt
local cos, sin, atan2, asin = math.cos, math.sin, math.atan2, math.asin
local max, min, Clamp = math.max, math.min, math.Clamp
local halfpi = math.pi * 0.5
local radunit = 180 / math.pi
local surface = surface
local RealFrameTime = RealFrameTime
local Vector = Vector
local zerovec, zeroang = Vector(), Angle()

local circlemask = Material('fastcmd/hud/circlemask')

local function Elasticity(x)
	if x >= 1 then return 1 end
	return x * 1.4301676 + sin(x * 4.0212386) * 0.55866
end

local function DrawWheel2D(size, wdata, state, preview)
	-- 绘制 HUD
	-- size 菜单尺寸 (直径)
	-- wdata 指令数据
	-- state 尺寸插值比例
	state = max(state, 0)

	local x, y = gui.MouseX(), gui.MouseY()
	local sx, sy = 0, 0
	local w, h = ScrW(), ScrH()
	if istable(preview) then
		-- 没什么卵用, 只是为了方便不用渲染参数绘制预览
		sx, sy = preview.x, preview.y
		w, h = preview.w, preview.h	
	end
	local cx, cy = sx + w * 0.5, sy + h * 0.5
	
	local stateinterp = Elasticity(state)
	 
	-- 使用插值后的大小, 图标大小使用等分占比
	size = max(size, 0) * stateinterp
	local rootcache = wdata.cache
	local iconsize = rootcache.iconsize * size
	local centersize = rootcache.centersize * size
	local fade = rootcache.fade * state

	draw.NoTexture()
	-- 淡入黑色背景
	surface.SetDrawColor(0, 0, 0, fade)
	surface.DrawRect(sx, sy, w, h)
	
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
	if wdata.autoclip then 
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
		for i, data in ipairs(wdata.metadata) do	 
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


	for i, data in ipairs(wdata.metadata) do	 
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
	if wdata.autoclip then 
		render.SetStencilEnable(false)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(rootcache.edge)

		for i, data in ipairs(wdata.metadata) do	 
			local cache = data.cache
			local lpos = size * cache.dir * (0.5 + cache.addlen * 0.1)

			surface.DrawTexturedRectRotated(
				cx + lpos.x, 
				cy + lpos.y, 
				iconsize, iconsize, 0)
		end
	end
end

function FcmdDrawBounds(size, wdata)
	-- 绘制边界
	local w, h = ScrW(), ScrH()
	local cx, cy = w * 0.5, h * 0.5

	local rootcache = wdata.cache
	local centersize = rootcache.centersize * size
	local iconsize = rootcache.iconsize * size

	surface.DrawCircle(cx, cy, size * 0.5, 255, 255, 255, 255)
	surface.DrawCircle(cx, cy, centersize * 0.5, 255, 255, 255, 255)
	for i, data in ipairs(wdata.metadata) do	 
		local cache = data.cache
		local lpos = size * cache.dir * 0.5
		surface.DrawCircle(cx + lpos.x, cy + lpos.y, iconsize * 0.5, 255, 255, 255, 255)
	end
end

function FcmdCheckSelect(size, wdata)
	-- 检查选中
	-- 检查直径
	local w, h = ScrW(), ScrH()
	local cx, cy = w * 0.5, h * 0.5
	local dx, dy = gui.MouseX() - cx, gui.MouseY() - cy
	if dx * dx + dy * dy < size * size * 0.25 then return nil end -- 距离判断
	local mousedir = Vector(dx, dy, 0)

	-- 使用叉积计算碰撞
	local rootcache = wdata.cache
	for i, data in ipairs(wdata.metadata) do
		local bounds = data.cache.bounds
		local crossleft, crossright = mousedir:Cross(bounds[1]).z, mousedir:Cross(bounds[2]).z
		if crossleft < 0 and crossright > 0 then
			return i
		end
	end

	return 0
end

local startmartix = Matrix()
startmartix:SetTranslation(Vector())
startmartix:SetAngles(Angle(90, 0, -90))
function FcmdDrawWheel(size, wdata, state)
	-- 绘制 HUD
	local rootcache = wdata.cache 
	local rotate3d = rootcache.rotate3d
	if rotate3d > 0 then
		state = max(state, 0)
		local w, h = ScrW(), ScrH()
		local cx, cy = w * 0.5, h * 0.5
		
		-- 计算变换矩阵
		-- 这个Start3D2D用不明白, 只能用两次旋转合成了
		local cammartix
		if rootcache.selectIdx ~= nil then
			local dx, dy = gui.MouseX() - cx, gui.MouseY() - cy
			local dis = sqrt(dx * dx + dy * dy)
			local sina, cosa = sin(rotate3d), cos(rotate3d)
			local pitch = atan2(dx / dis * sina, cosa) * radunit
			local roll = asin(dy / dis * sina) * radunit
			local rotate = Matrix()
			rotate:SetAngles(Angle(pitch, 0, roll))
			cammartix = rotate * startmartix
		else
			cammartix = startmartix
		end
		local campos, camang = Vector(cx, -cy, 0) - cammartix:GetForward() * 1200, cammartix:GetAngles()

		
		local fade = rootcache.fade

		draw.NoTexture()
		-- 淡入黑色背景
		surface.SetDrawColor(0, 0, 0, fade * state)
		surface.DrawRect(0, 0, w, h)

		local old = DisableClipping(true)
		rootcache.fade = 0 -- 禁用2D的淡入绘制
		
		cam.Start3D(campos, camang, 60)
			cam.Start3D2D(zerovec, zeroang, 1)
				DrawWheel2D(size, wdata, state)
			cam.End3D2D() 
		cam.End3D()

		rootcache.fade = fade -- 恢复数据
		DisableClipping(old)
	else
		DrawWheel2D(size, wdata, state)
	end
end

FcmdDrawWheel2D = DrawWheel2D