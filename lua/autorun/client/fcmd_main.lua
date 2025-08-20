local Clamp = math.Clamp
local pcall = pcall
local ScrW, ScrH = ScrW, ScrH
local min, max = math.min, math.max
local sqrt = math.sqrt
local cos, sin, atan2, asin = math.cos, math.sin, math.atan2, math.asin
local gui = gui
local Vector, Matrix, Angle = Vector, Matrix, Angle
local draw, surface, hook = draw, surface, hook


include('core/fcmd_wheel.lua')
include('core/fcmd_execute.lua')
include('core/fcmd_file.lua')
include('core/fcmd_filter.lua')

local ExecuteCmd = FcmdExecuteCmd
local ExecuteBreak = FcmdExecuteBreak
local ExecuteCall = FcmdExecuteCall
local DrawWheel2D = FcmdDrawWheel2D
local CheckSelect = FcmdCheckSelect

local cmdfilter = FcmdGetCmdFilter()
-----------------------------
local cl_fcmd_wheel_size = CreateClientConVar('cl_fcmd_wheel_size', '500', true, false)
local cl_fcmdm_expand_key = CreateClientConVar('cl_fcmdm_expand_key', '0', true, false)
local cl_fcmd_call_key = CreateClientConVar('cl_fcmd_call_key', '0', true, false)
local cl_fcmdm_break_key = CreateClientConVar('cl_fcmdm_break_key', '0', true, false)
local cl_fcmd_wfile = CreateClientConVar('cl_fcmd_wfile', 'fastcmd/wheel/chat.json', true, false)
-----------------------------
local curcall
local curwdata
local expand = false

local function ExecuteCurBreak()
	-- 执行中断命令
	if not istable(curcall) then return end
	ExecuteBreak(curcall, cmdfilter)
end

local function GetCurCall() return curcall end
local function SetCurCall(target) 
	if istable(target) then target.press = nil end -- 重置按下状态, 防止切换后第一次是弹起
	if curcall ~= target then ExecuteCurBreak() end
	curcall = target 
end

local function GetCurWData() return curwdata end
local function SetCurWData(target) 
	curwdata = target 
	SetCurCall(nil)
end

local function ExpandWheel(state)
	-- 展开UI
	if not istable(curwdata) then
		expand = false
		return 
	end

	gui.EnableScreenClicker(state)
	expand = state
	
	if state then
		if isstring(curwdata.soundexpand) then
			surface.PlaySound(curwdata.soundexpand)
		end
	else
		if isstring(curwdata.soundclose) then
			surface.PlaySound(curwdata.soundclose)
		end

		-- 关闭时更改选中
		local selectIdx = curwdata.cache.selectIdx
		if selectIdx ~= nil and selectIdx ~= 0 then
			curwdata.cache.selectedIdx = selectIdx
			SetCurCall(curwdata.metadata[selectIdx].call)
			if istable(curcall) then ExecuteCmd(curcall.sexecute) end
		end
		curwdata.cache.selectIdx = nil
	end
end

local function GetExpand() return expand end
local function SetExpand(target) ExpandWheel(target) end

local function ExecuteCurCall(state)
	-- 执行选中
	-- 展开ui时不执行
	if expand or not istable(curcall) then return end
	// PrintTable(curcall)
	ExecuteCall(curcall, state, cmdfilter)
end

FcmdmExecuteCurCall = ExecuteCurCall
FcmdmExecuteCurBreak = ExecuteCurBreak
FcmdmExpandWheel = ExpandWheel
FcmdmGetCurWData = GetCurWData
FcmdmSetCurWData = SetCurWData
FcmdmGetCurCall = GetCurCall
FcmdmSetCurCall = SetCurCall
FcmdmGetExpand = GetExpand
FcmdmSetExpand = SetExpand

function FcmdmLoadCurWData(filename)
	LocalPlayer():ConCommand('cl_fcmd_wfile ""')
	LocalPlayer():ConCommand(string.format('cl_fcmd_wfile "%s"', filename))
end

function FcmdmReloadCurWData()
	local filename = cl_fcmd_wfile:GetString()
	LocalPlayer():ConCommand('cl_fcmd_wfile ""')
	LocalPlayer():ConCommand(string.format('cl_fcmd_wfile "%s"', filename))
end

function FcmdmClearCurWData()
	LocalPlayer():ConCommand('cl_fcmd_wfile ""')
end

table.Merge(cmdfilter, {
	['+fcmdm_expand'] = true,
	['-fcmdm_expand'] = true,
	['+fcmdm_call'] = true,
	['-fcmdm_call'] = true,
	['fcmdm_break'] = true
})

cvars.AddChangeCallback('cl_fcmd_wfile', function(name, old, new) 
	local newdata
	if new ~= '' then
		newdata = FcmdLoadWheelData(new)
		if istable(newdata) then 
			local loadsound = newdata.loadsound
			if isstring(loadsound) and loadsound ~= '' then
				surface.PlaySound(loadsound)
			else
				surface.PlaySound('Weapon_AR2.Reload_Push')
			end
		end
	end

	SetCurWData(newdata)
end, 'aaa')

concommand.Add('+fcmdm_expand', function(ply) ExpandWheel(true) end)
concommand.Add('-fcmdm_expand', function(ply) ExpandWheel(false) end)
concommand.Add('+fcmdm_call', function(ply) ExecuteCurCall(true) end)
concommand.Add('-fcmdm_call', function(ply) ExecuteCurCall(false) end)

concommand.Add('fcmdm_break', function(ply) ExecuteCurBreak() end)

local radunit = 180 / math.pi
local zerovec, zeroang = Vector(), Angle()
local startmartix = Matrix()
startmartix:SetTranslation(Vector())
startmartix:SetAngles(Angle(90, 0, -90))
local function DrawWheel(size, wdata, state)
	-- 绘制轮盘 并 运行Hook
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
				hook.Run('FcmdPreDrawWheel2D', size, wdata, state)
				DrawWheel2D(size, wdata, state)
				hook.Run('FcmdPostDrawWheel2D', size, wdata, state)
			cam.End3D2D() 
		cam.End3D()

		rootcache.fade = fade -- 恢复数据
		DisableClipping(old)
	else
		hook.Run('FcmdPreDrawWheel2D', size, wdata, state)
		DrawWheel2D(size, wdata, state)
		hook.Run('FcmdPostDrawWheel2D', size, wdata, state)
	end
end
FcmdmDrawWheel = DrawWheel

-----------------------------
local expandKey = false
local function ExpandKeyEvent()
	-- 展开键事件 (有绑定时边沿触发)
	local key = cl_fcmdm_expand_key:GetInt()
	if key == 0 then return end
	local current = input.IsKeyDown(key) or input.IsMouseDown(key)
	if expandKey ~= current then 
		ExpandWheel(current) 
	end
	expandKey = current
end

local callKey = false
local function CallKeyEvent()
	-- 执行键事件 (有绑定时边沿触发)
	local key = cl_fcmd_call_key:GetInt()
	if key == 0 then return end
	local current = input.IsKeyDown(key) or input.IsMouseDown(key)
	if callKey ~= current then 
		ExecuteCurCall(current) 
	end
	callKey = current
end

local breakKey = false
local function BreakKeyEvent()
	-- 中断键事件 (有绑定时上升沿触发)
	local key = cl_fcmdm_break_key:GetInt()
	if key == 0 then return end
	local current = input.IsKeyDown(key) or input.IsMouseDown(key)
	if current and breakKey ~= current then 
		ExecuteCurBreak() 
	end
	breakKey = current
end

concommand.Add('fcmd_add_hook', function(ply, cmd, args)
	hook.Add('Think', 'fcmd_think', function()
		if not istable(curwdata) then return end

		-- 按键事件
		ExpandKeyEvent()
		CallKeyEvent()
		BreakKeyEvent()

		if not expand then return end 

		-- 检查选中
		local rootcache = curwdata.cache
		local selectIdx = CheckSelect(
			rootcache.centersize * cl_fcmd_wheel_size:GetInt(), 
			curwdata
		)

		-- 选中变化 (播放音效并触发事件)
		if rootcache.selectIdx ~= selectIdx then
			hook.Run('FcmdSelect', curwdata.metadata[selectIdx])
			if selectIdx == nil or selectIdx == 0 then
				if isstring(curwdata.soundgiveup) and curwdata.soundgiveup ~= '' then
					surface.PlaySound(curwdata.soundgiveup)
				else
					surface.PlaySound('fastcmd/zoomout.wav')
				end
			else
				if isstring(curwdata.soundselect) and curwdata.soundselect ~= '' then
					surface.PlaySound(curwdata.soundselect)
				else
					surface.PlaySound('fastcmd/zoomin.wav')
				end
			end
		end
		rootcache.selectIdx = selectIdx
	end)

	local expandstate = 0
	hook.Add('HUDPaint', 'fcmd_draw', function() 
		if expand then
			expandstate = Clamp(expandstate + 5 * RealFrameTime(), 0, 1)
		else
			expandstate = Clamp(expandstate - 5 * RealFrameTime(), 0, 1)
		end
		if expandstate == 0 then 
			return 
		end
		
		-- 使用多个全局渲染设置, 异常时必须着重处理
		local succ, err = pcall(DrawWheel, cl_fcmd_wheel_size:GetInt(), curwdata, expandstate)
		
		if not succ then	
			render.ClearStencil()
			render.SetStencilEnable(false)
			render.OverrideColorWriteEnable(false)
			gui.EnableScreenClicker(false)
			
			hook.Remove('Think', 'fcmd_think')
			hook.Remove('HUDPaint', 'fcmd_draw')

			ErrorNoHaltWithStack(err)
			FcmdError('#fcmdm.err.fatal', '#fcmdm.err.hook_die')
			ExpandWheel(false)
		end
	end)
end)

hook.Add('KeyPress', 'fcmd_init', function(ply, key)
	if key == IN_FORWARD or key == IN_BACK then
		LocalPlayer():ConCommand('fcmd_add_hook')
		FcmdmReloadCurWData()
		FcmdHelp('#fcmdm.help.use')
		hook.Remove('KeyPress', 'fcmd_init')
	end
end)
