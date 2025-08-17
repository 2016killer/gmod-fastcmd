include('fcmd_notify.lua')

local cicondefault = Material('fastcmd/hud/cicon.png')
local arrowdefault = Material('fastcmd/hud/arrow.png')
local icondefault = Material('fastcmd/hud/default.jpg')
local edgedefault = Material('fastcmd/hud/edge.png')
local rotate3d = 10
local cl_fcmd_notify = CreateClientConVar('cl_fcmd_notify', '1', true, false)
------------------------------
local function numdefault(num, default)
	return isnumber(num) and num or default
end

local function isjsonpath(filename)
	local len = #filename
	return len >= 5 and string.lower(string.sub(filename, len - 4, len)) == '.json'
end
------------------------------
function FcmdLoadMaterials(path, failed)
	-- 加载游戏目录或缓存目录的材质, 加载缓存目录材质
	if tonumber(path) ~= nil then
		local wsid = path
		local asyncmat = {
			mat = icondefault, 
			downloading = true
		}

		local start = CurTime()
		steamworks.FileInfo(wsid, function(result)
			local err = result.error
			if err then
				FcmdWarn('#fcmd.warn.query', tostring(err), '#fcmd.help.query_addon_info', 'wsid:'..tostring(wsid))
			else
				local previewid = result.previewid
				steamworks.Download(previewid, true, function(name)
					asyncmat.downloading = false
					if name == nil then
						FcmdWarn('#fcmd.warn.download', '#fcmd.help.download_addon_pre', 'previewid:'..tostring(previewid))
						asyncmat.mat = failed
					else
						asyncmat.mat = AddonMaterial(name)
						if asyncmat.mat == nil then 
							FcmdWarn('#fcmd.warn.quote', name)
							asyncmat.mat = failed 
						end
						print('加载时间:', CurTime() - start)
					end
				end)	
			end
		end)
	
		return asyncmat
	elseif isstring(path) and path ~= '' then
		return Material(path)
	else
		return failed
	end
end
 
function FcmdParseJSON2WheelData(json)
	-- 解析json为wheeldata并伴随界面提示
	local wdata = util.JSONToTable(json)
	if not istable(wdata) then 
		FcmdError('#fcmd.err.parse', '#fcmd.err.json_err')
		return nil
	else
		-- 自动修复metadata
		if not istable(wdata.metadata) then
			FcmdWarn('#fcmd.warn.parse', '#fcmd.warn.loss_field', 'metadata')
			wdata.metadata = {}
		end
	end

	---- 计算缓存
	local rootcache = {
		selectIdx = nil, -- 选中的索引
	}
	wdata.cache = rootcache

	-- 加载图标材质
	rootcache.cicon = FcmdLoadMaterials(wdata.cicon, cicondefault)
	rootcache.arrow = FcmdLoadMaterials(wdata.arrow, arrowdefault)
	rootcache.edge = FcmdLoadMaterials(wdata.edge, edgedefault)

	---- 变量边界

	-- 比例、角度边界大小
	local angbound = math.min(
		math.pi * 2 / math.max(#wdata.metadata, 1) * math.max(numdefault(wdata.iconsize, 0.5), 0), 
		math.pi * 0.667
	)
	
	rootcache.fade = math.max(numdefault(wdata.fade, 100), 0)
	rootcache.centersize = math.max(numdefault(wdata.centersize, 0.5), 0)
	rootcache.iconsize = math.sin(angbound * 0.25) * 2
	rootcache.rotate3d = numdefault(wdata.rotate3d, 10) * math.pi / 180

	-- 生成位置、加载材质
	local step = math.pi * 2 / #wdata.metadata
	for i, node in pairs(wdata.metadata) do 
		-- 元数据检测并修复
		// if true then continue end
		if not istable(node) then
			FcmdWarn('#fcmd.warn.parse', '#fcmd.warn.invalid_element', '"'..tostring(i)..'"')
			node = {}
			wdata.metadata[i] = node
		end
		if not isnumber(i) then
			FcmdWarn('#fcmd.warn.parse', '#fcmd.warn.invalid_idx', '"'..tostring(i)..'"')
			i = 0
		end

		local ang = -0.5 * math.pi + (i - 1) * step
		local angleft = ang - 0.5 * angbound
		local angright = ang + 0.5 * angbound

		local nodecache = {
			dir = Vector(math.cos(ang), math.sin(ang), 0),
			addlen = 0,
			bounds = {
				Vector(math.cos(angleft), math.sin(angleft), 0),
				Vector(math.cos(angright), math.sin(angright), 0),
			}
		}

		nodecache.icon = FcmdLoadMaterials(node.icon, icondefault)

		node.cache = nodecache
	end
	
	// PrintTable(wdata)
	return wdata
end

function FcmdDumpsWheelData2JSON(wdata)
	-- 序列化数据
	if not istable(wdata) then
		FcmdError('#fcmd.err.dumps', '#fcmd.err.not_table')
		return nil
	end

	wdata.cache = nil
	if istable(wdata.metadata) then
		for _, node in pairs(wdata.metadata) do
			node.cache = nil
		end
	end

	return util.TableToJSON(wdata, true)
end
------------------------------ 
function FcmdLoadWheelData(filepath)
	-- 从DATA目录下的文件中获取wheeldata
	if not isjsonpath(filepath) then
		FcmdError('#fcmd.err.load', filepath, '#fcmd.err.not_json_suffix')
		return nil
	end

	if file.IsDir(filepath, 'DATA') then
		FcmdError('#fcmd.err.load', filepath, '#fcmd.err.is_folder')

		return nil
	end

	if not file.Exists(filepath, 'DATA') then
		FcmdError('#fcmd.err.load', filepath, '#fcmd.err.file_not_exist')
		return nil
	end

	local json = file.Read(filepath, 'DATA')	
	return FcmdParseJSON2WheelData(json)
end

function FcmdSaveWheelData(wdata, filepath, override)
	-- 保存wheeldata为DATA目录下的文件
	if not isjsonpath(filepath) then
		FcmdError('#fcmd.err.save', filepath, '#fcmd.err.not_json_suffix')
		return false
	end

	if file.IsDir(filepath, 'DATA') then
		FcmdError('#fcmd.err.save', filepath, '#fcmd.err.file_exist')
		return false
	end

	if not override and file.Exists(filepath, 'DATA') then
		FcmdError('#fcmd.err.save', filepath, '#fcmd.err.file_exist')
		return false
	end

	local json = FcmdDumpsWheelData2JSON(wdata)
	file.Write(filepath, json)

	return true
end

function FcmdDeleteJsonFile(filepath)
	-- 删除文件 (DATA任何json文件都能通过此删除, 注意安全)
	if not isjsonpath(filepath) then
		return true
	end

	if not file.Exists(filepath, 'DATA') then
		return true
	end

	if file.IsDir(filepath, 'DATA') then
		return true
	end

	file.Delete(filepath)
	return true
end

function FcmdCopyJsonFile(origin, target)
	-- 拷贝 (DATA任何json文件都能通过此拷贝, 注意安全)

	if not isjsonpath(origin) then
		FcmdError('#fcmd.err.copy', origin, '#fcmd.err.not_json_suffix')
		return false
	end

	if not isjsonpath(target) then
		FcmdError('#fcmd.err.copy', target, '#fcmd.err.not_json_suffix')
		return false
	end

	if file.IsDir(origin, 'DATA') then
		FcmdError('#fcmd.err.copy', origin, '#fcmd.err.is_folder')
		return false
	end

	if not file.Exists(origin, 'DATA') then
		FcmdError('#fcmd.err.copy', origin, '#fcmd.err.file_not_exist')
		return false
	end

	local path = string.GetPathFromFilename(target)
	local name = string.sub(string.sub(target, #path + 1, -1), 1, -6) 
	local succ = false
	for i = 0, 10 do
		local newtarget = i == 0 and target or (path..name..' ('..i..').json')
		if not file.Exists(newtarget, 'DATA') then
			target = newtarget
			succ = true
			break
		end
	end

	if succ then
		file.Write(target, file.Read(origin, 'DATA'))
	else
		FcmdError('#fcmd.err.copy', target, '#fcmd.err.file_exist')
	end
	
	return succ
end

function FcmdCreateWheelData(folder)
	-- 创建新文件
	folder = string.Trim(folder)
	
	if folder ~= '' and folder[-1] ~= '/' and folder[-1] ~= '\\' then
		file.CreateDir(folder)
		folder = folder..'/'
	end
	
	local filepath = folder..'wnew_'..tostring(os.time())..'.json'

	file.Write(
		filepath, 
		[[
{
	"autoclip": true,
	"metadata": [
		{
			"call": {
				"pexecute": "fcmdm_example \"Hello World\"",
				"rexecute": "fcmdm_example \"Good Bye\""
			},
			"icon": "fastcmd/hud/world.jpeg"
		},
		{
			"call": {
				"pexecute": "fcmdm_example \"Hello Garry's Mod\"",
				"rexecute": "fcmdm_example \"Good Bye\""
			},
			"icon": "fastcmd/hud/gmod.jpeg"
		},
		{
			"call": {
				"pexecute": "fcmdm_example \"Hello Workshop\"",
				"rexecute": "fcmdm_example \"Good Bye\""
			},
			"icon": "fastcmd/hud/workshop.jpeg"
		}
	]
}	
		]]
	)

	return filepath
end

function FcmdCopyJsonFileContent(filepath)
	-- 拷贝文件内容
	if not isjsonpath(filepath) then
		FcmdError('#fcmd.err.copy', filepath, '#fcmd.err.not_json_suffix')
		return false
	end

	if file.IsDir(filepath, 'DATA') then
		FcmdError('#fcmd.err.copy', filepath, '#fcmd.err.is_folder')
		return false
	end

	if not file.Exists(filepath, 'DATA') then
		FcmdError('#fcmd.err.copy', filepath, '#fcmd.err.file_not_exist')
		return false
	end

	SetClipboardText(file.Read(filepath, 'DATA'))
	
	return true
end


concommand.Add('fcmd_example', function(ply, cmd, args) 
	local msg = args[1] or 'Hello'
	ply:EmitSound('friends/message.wav')
	ply:PrintMessage(HUD_PRINTTALK, msg) 
end)

if not file.Exists('fastcmd/wheel/chat.json', 'DATA') then
	local filepath = FcmdCreateWheelData('fastcmd/wheel')
	file.Rename(filepath, 'fastcmd/wheel/chat.json')
	print('创建 fastcmd/wheel/chat.json')
end