local Split = string.Split
local Trim = string.Trim

local cmdfilter = {
	['+fcmd_expand'] = true,
	['-fcmd_expand'] = true,
	['+fcmd_call'] = true,
	['-fcmd_call'] = true,
	['fcmd_break'] = true
}

local function CmdFilter(cmd)
	-- 过滤指定指令, 防止无限递归
	local result = {}

    -- 以;分割所有子串
    for _, part in ipairs(Split(cmd, ';')) do
		part = Trim(part)
        if not cmdfilter[part] then
        	table.insert(result, part)
        end
    end

    return table.concat(result, ';')
end

local function AutoParseRexecute(cmd)
    -- 自动解析释放指令：保留+开头的子串，并将+替换为-
    local result = {}

    -- 以;分割所有子串
    for _, part in ipairs(Split(cmd, ';')) do
		part = Trim(part)
        if part[1] == '+' then
            table.insert(result, '-'..string.sub(part, 2))
        end
    end
    return table.concat(result, ';')
end

local function ExecuteCmd(cmd)
	if not isstring(cmd) then return end
	LocalPlayer():ConCommand(CmdFilter(cmd))
end

function FcmdExecuteCall(call, press)
	-- 执行指令
	// PrintTable(call)
	if press then
		ExecuteCmd(call.pexecute)
	else
		if isstring(call.rexecute) then
			ExecuteCmd(call.rexecute)
		elseif isstring(call.pexecute) then
			ExecuteCmd(AutoParseRexecute(call.pexecute))
		end
	end
end

FcmdExecuteCmd = ExecuteCmd
FcmdAutoParseRexecute = AutoParseRexecute