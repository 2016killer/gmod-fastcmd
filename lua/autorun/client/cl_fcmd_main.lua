include('cl_fcmd_core.lua')

local Clamp = math.Clamp
local Execute = fcmd_Execute
local Break = fcmd_Break
local DrawHud = fcmd_DrawHud
local CheckSelect = fcmd_CheckSelect
-----------------------------
local fcmddata
local function BreakCmd()
	-- 执行中断命令
	if not istable(fcmddata) then return end
	Break(fcmddata.breakcmd)
end

local expand = false
local calldata
local function ExpandUI(state)
	-- 展开UI
	if not istable(fcmddata) then
		expand = false
		return 
	end

	BreakCmd()
	gui.EnableScreenClicker(state)
	expand = state
	
	if state then
		if isstring(fcmddata.soundexpand) then
			LocalPlayer():EmitSound(fcmddata.soundexpand)
		end
	else
		if isstring(fcmddata.soundclose) then
			LocalPlayer():EmitSound(fcmddata.soundclose)
		end

		-- 关闭时更改选中
		local selectIdx = fcmddata.cache.selectIdx
		if selectIdx ~= nil and selectIdx ~= 0 then
			fcmddata.cache.selectedIdx = selectIdx
			calldata = fcmddata.metadata[selectIdx].call
		end
	end
end

local function ExecuteSelected(state)
	-- 执行选中
	-- 展开ui时不执行
	if expand or not istable(calldata) then return end
	Execute(calldata, state)
end

fcmdm_ExecuteSelected = ExecuteSelected
fcmdm_ExpandUI = ExpandUI
fcmdm_BreakCmd = BreakCmd

function fcmdm_GetCurrentFcmdData() return fcmddata end
function fcmdm_SetCurrentFcmdData(target) fcmddata = target end

function fcmdm_GetCurrentCallData() return calldata end
function fcmdm_SetCurrentCallData(target) calldata = target end

function fcmdm_GetExpand() return expand end
function fcmdm_SetExpand(target) ExpandUI(target) end

function fcmdm_LoadsFcmdDataFromFile(filename)
	if filename == '' or filename == '0' or filename == 'empty' then
		// print('fcmd文件无效')
		return
	elseif filename:match('%.json$') == nil then
		error('必须是json格式')
	end

	local root = 'fastcmd'
	local path = root..'/'..filename
	local json = file.Read(path, 'DATA')	
	local data = fcmd_LoadsFcmdData(json)
	fcmddata = data
end

concommand.Add('+fcmd_expand', function(ply) ExpandUI(true) end)
concommand.Add('-fcmd_expand', function(ply) ExpandUI(false) end)
concommand.Add('+fcmd_execute', function(ply) ExecuteSelected(true) end)
concommand.Add('-fcmd_execute', function(ply) ExecuteSelected(false) end)
concommand.Add('fcmd_break', function(ply) BreakCmd() end)

concommand.Add('fcmd_example', function(ply, cmd, args) 
	local msg = args[1] or 'Hello Workshop'
	ply:EmitSound('Buttons.snd15')
	ply:PrintMessage(HUD_PRINTTALK, msg) 
end)

-----------------------------
local cl_fcmd_menu_size = CreateClientConVar('cl_fcmd_menu_size', '500', true, false)
local cl_fcmd_expand_key = CreateClientConVar('cl_fcmd_expand_key', '0', true, false)
local cl_fcmd_execute_key = CreateClientConVar('cl_fcmd_execute_key', '0', true, false)
local cl_fcmd_break_key = CreateClientConVar('cl_fcmd_break_key', '0', true, false)
local cl_fcmd_file = CreateClientConVar('cl_fcmd_file', '', true, false)
-----------------------------
local expandKey = false
local function ExpandKeyEvent()
	-- 展开键事件 (有绑定时边沿触发)
	local key = cl_fcmd_expand_key:GetInt()
	if key == 0 then return end
	local current = input.IsKeyDown(key) or input.IsMouseDown(key)
	if expandKey ~= current then 
		ExpandUI(current) 
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
		ExecuteSelected(current) 
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
		BreakCmd() 
	end
	breakKey = current
end

hook.Add('Think', 'fcmd_think', function()
	if not istable(fcmddata) then return end

	-- 按键事件
	ExpandKeyEvent()
	ExecuteKeyEvent()
	BreakKeyEvent()

	if not expand then return end 

	-- 检查选中
	local rootcache = fcmddata.cache
	local selectIdx = CheckSelect(
		rootcache.centersize * cl_fcmd_menu_size:GetInt(), 
		fcmddata
	)

	-- 选中变化 (播放音效并触发事件)
	if rootcache.selectIdx ~= selectIdx then
		hook.Run('FcmdSelect', fcmddata.metadata[selectIdx])
		if selectIdx == nil or selectIdx == 0 then
			if isstring(fcmddata.soundgiveup) then
				LocalPlayer():EmitSound(fcmddata.soundgiveup)
			else
				LocalPlayer():EmitSound('fastcmd/zoomout.wav')
			end
		else
			if isstring(fcmddata.soundselect) then
				LocalPlayer():EmitSound(fcmddata.soundselect)
			else
				LocalPlayer():EmitSound('fastcmd/zoomin.wav')
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
	fcmd_DrawHud(cl_fcmd_menu_size:GetInt(), fcmddata, expandstate)
end)


cvars.AddChangeCallback('cl_fcmd_file', function(name, old, new) 
	local succ, err = pcall(fcmdm_LoadsFcmdDataFromFile, new) 
	if succ then
		LocalPlayer():EmitSound('Buttons.snd34', 75, 100)
	else
		LocalPlayer():EmitSound('Buttons.snd10', 75, 100)
		fcmddata = nil
		Error('fcmd: '..err..'\n')
		print('检查文件路径或内容')
	end
end, 'aaa')

pcall(fcmdm_LoadsFcmdDataFromFile, cl_fcmd_file:GetString())

