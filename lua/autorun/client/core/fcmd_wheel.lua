local ScrW, ScrH = ScrW, ScrH
local gui = gui
local sin, atan2 = math.sin, math.atan2
local max, min, Clamp = math.max, math.min, math.Clamp
local halfpi = math.pi * 0.5
local radunit = 180 / math.pi
local surface = surface
local RealFrameTime = RealFrameTime
local Vector = Vector
local circlemask = Material('fastcmd/hud/circlemask')

local function Elasticity(x)
	if x >= 1 then return 1 end
	return x * 1.4301676 + sin(x * 4.0212386) * 0.55866
end


local function SetMaterial(mat)
	if istable(mat) then
		-- 处理异步材质
		surface.SetMaterial(mat.mat)
	else
		surface.SetMaterial(mat)
	end
end

function FcmdDrawWheel2D(size, wdata, state, preview)
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
	SetMaterial(rootcache.cicon)
	surface.DrawTexturedRectRotated(cx, cy, centersize, centersize, 0)

	-- 箭头图标绘制
	if rootcache.selectIdx ~= nil then
		local mouseang = (atan2(y - cy, x - cx) + halfpi) * radunit
		SetMaterial(rootcache.arrow)
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

		SetMaterial(cache.icon)
		surface.DrawTexturedRectRotated(cx + lpos.x, cy + lpos.y, iconsize, iconsize, 0)
	end

	-- 绘制边缘
	if wdata.autoclip then 
		render.SetStencilEnable(false)
		surface.SetDrawColor(255, 255, 255, 255)
		SetMaterial(rootcache.edge)

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

function FcmdDrawBounds(size, wdata, preview)
	-- 绘制边界

	local sx, sy = 0, 0
	local w, h = ScrW(), ScrH()
	if istable(preview) then
		-- 没什么卵用, 只是为了方便不用渲染参数绘制预览
		sx, sy = preview.x, preview.y
		w, h = preview.w, preview.h	
	end
	local cx, cy = sx + w * 0.5, sy + h * 0.5

	local rootcache = wdata.cache
	local centersize = rootcache.centersize * size

	surface.DrawCircle(cx, cy, size * 0.5, 255, 255, 0)
	surface.DrawCircle(cx, cy, centersize * 0.5, 0, 255, 0)
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
