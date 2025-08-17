local Split = string.Split
local Trim = string.Trim

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

local function ExecuteCmd(cmd, filter)
	if not isstring(cmd) or cmd == '' then return end
	-- 过滤指定指令, 防止无限递归
	local result = {}

    -- 以;分割所有子串
	if istable(filter) then
		for _, part in ipairs(Split(cmd, ';')) do
			part = Trim(part)
			if not filter[part] then
				table.insert(result, part)
			end
		end
		cmd = table.concat(result, ';')
	end

	LocalPlayer():ConCommand(cmd)
end

function FcmdExecuteCall(call, press, filter)
	-- 执行指令
	// PrintTable(call)
	if press then
		ExecuteCmd(call.pexecute, filter)
	else
		if isstring(call.rexecute) then
			ExecuteCmd(call.rexecute, filter)
		elseif isstring(call.pexecute) then
			ExecuteCmd(AutoParseRexecute(call.pexecute), filter)
		end
	end
end

FcmdExecuteCmd = ExecuteCmd
FcmdAutoParseRexecute = AutoParseRexecute


