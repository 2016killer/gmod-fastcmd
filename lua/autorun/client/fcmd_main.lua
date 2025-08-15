local Clamp = math.Clamp
local pcall = pcall

include('core/fcmd_wheel.lua')
include('core/fcmd_execute.lua')
include('core/fcmd_file.lua')
local ExecuteCmd = FcmdExecuteCmd
local ExecuteCall = FcmdExecuteCall
local DrawWheel = FcmdDrawWheel
local CheckSelect = FcmdCheckSelect
-----------------------------
local cl_fcmd_menu_size = CreateClientConVar('cl_fcmd_menu_size', '500', true, false)
local cl_fcmd_expand_key = CreateClientConVar('cl_fcmd_expand_key', '0', true, false)
local cl_fcmd_execute_key = CreateClientConVar('cl_fcmd_execute_key', '0', true, false)
local cl_fcmd_break_key = CreateClientConVar('cl_fcmd_break_key', '0', true, false)
local cl_fcmd_wfile = CreateClientConVar('cl_fcmd_wfile', 'fastcmd/wheel/chat.json', true, false)
-----------------------------
local curwdata
local function ExecuteBreak()
	-- 执行中断命令
	if not istable(curwdata) then return end
	ExecuteCmd(curwdata.breakcmd)
end

local expand = false
local curcall
local function ExpandWheel(state)
	-- 展开UI
	if not istable(curwdata) then
		expand = false
		return 
	end

	ExecuteBreak()
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
			curcall = curwdata.metadata[selectIdx].call
		end
		curwdata.cache.selectIdx = nil
	end
end

local function ExecuteCurCall(state)
	-- 执行选中
	-- 展开ui时不执行
	if expand or not istable(curcall) then return end
	ExecuteCall(curcall, state)
end

FcmdmExecuteCurCall = ExecuteCurCall
FcmdmExpandWheel = ExpandWheel
FcmdmExecuteBreak = ExecuteBreak

function FcmdmGetCurWData() return curwdata end
function FcmdmSetCurWData(target) curwdata = target end

function FcmdmGetCurCall() return curcall end
function FcmdmSetCurCall(target) curcall = target end

function FcmdmGetExpand() return expand end
function FcmdmSetExpand(target) ExpandWheel(target) end

function FcmdmLoadCurWData(filename)
	LocalPlayer():ConCommand('cl_fcmd_wfile ""')
	LocalPlayer():ConCommand('cl_fcmd_wfile '..filename)
end

function FcmdmReloadCurWData()
	local filename = cl_fcmd_wfile:GetString()
	LocalPlayer():ConCommand('cl_fcmd_wfile ""')
	LocalPlayer():ConCommand('cl_fcmd_wfile '..filename)
end

function FcmdmClearCurWData()
	LocalPlayer():ConCommand('cl_fcmd_wfile ""')
end

cvars.AddChangeCallback('cl_fcmd_wfile', function(name, old, new) 
	if new ~= '' then
		local newdata, _ = FcmdLoadWheelData(new)
		if istable(newdata) then 
			if isstring(newdata.loadsound) and newdata.loadsound ~= '' then
				surface.PlaySound(soundpath)
			else
				surface.PlaySound('Weapon_AR2.Reload_Push')
			end
		end
	end

	curwdata = newdata
	curcall = nil
end, 'aaa')

concommand.Add('+fcmd_expand', function(ply) ExpandWheel(true) end)
concommand.Add('-fcmd_expand', function(ply) ExpandWheel(false) end)
concommand.Add('+fcmd_call', function(ply) ExecuteCurCall(true) end)
concommand.Add('-fcmd_call', function(ply) ExecuteCurCall(false) end)

concommand.Add('fcmd_break', function(ply) ExecuteBreak() end)
concommand.Add('fcmd_example', function(ply, cmd, args) 
	local msg = args[1] or 'Hello Workshop'
	ply:EmitSound('friends/message.wav')
	ply:PrintMessage(HUD_PRINTTALK, msg) 
end)

-----------------------------
local expandKey = false
local function ExpandKeyEvent()
	-- 展开键事件 (有绑定时边沿触发)
	local key = cl_fcmd_expand_key:GetInt()
	if key == 0 then return end
	local current = input.IsKeyDown(key) or input.IsMouseDown(key)
	if expandKey ~= current then 
		ExpandWheel(current) 
	end
	expandKey = current
end

local executeKey = false
local function ExecuteKeyEvent()
	-- 执行键事件 (有绑定时边沿触发)
	local key = cl_fcmd_execute_key:GetInt()
	if key == 0 then return end
	local current = input.IsKeyDown(key) or input.IsMouseDown(key)
	if executeKey ~= current then 
		ExecuteCurCall(current) 
	end
	executeKey = current
end

local breakKey = false
local function BreakKeyEvent()
	-- 中断键事件 (有绑定时上升沿触发)
	local key = cl_fcmd_break_key:GetInt()
	if key == 0 then return end
	local current = input.IsKeyDown(key) or input.IsMouseDown(key)
	if current and breakKey ~= current then 
		ExecuteBreak() 
	end
	breakKey = current
end

concommand.Add('fcmd_add_hook', function(ply, cmd, args)
	hook.Add('Think', 'fcmd_think', function()
		if not istable(curwdata) then return end

		-- 按键事件
		ExpandKeyEvent()
		ExecuteKeyEvent()
		BreakKeyEvent()

		if not expand then return end 

		-- 检查选中
		local rootcache = curwdata.cache
		local selectIdx = CheckSelect(
			rootcache.centersize * cl_fcmd_menu_size:GetInt(), 
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
		local succ, err = pcall(DrawWheel, cl_fcmd_menu_size:GetInt(), curwdata, expandstate)
		
		if not succ then
			ErrorNoHaltWithStack(err)
			FcmdError('#fcmd.err.fatal', '#fcmd.err.hook_die')

			render.ClearStencil()
			render.SetStencilEnable(false)
			render.OverrideColorWriteEnable(false)
			gui.EnableScreenClicker(false)
			ExpandWheel(false)

			hook.Remove('Think', 'fcmd_think')
			hook.Remove('HUDPaint', 'fcmd_draw')
		end
	end)
end)

hook.Add('KeyPress', 'fcmd_init', function(ply, key)
	if key == IN_FORWARD or key == IN_BACK then
		LocalPlayer():ConCommand('fcmd_add_hook')
		FcmdmReloadCurWData()
		FcmdHelp('#fcmd.help.use')
		hook.Remove('KeyPress', 'fcmd_init')
	end
end)
