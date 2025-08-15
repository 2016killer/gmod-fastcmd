include('fcmd_notify.lua')

FcmdWheelDataRoot = 'fastcmd/wheel'
local cicondefault = Material('fastcmd/hud/cicon.png')
local arrowdefault = Material('fastcmd/hud/arrow.png')
local icondefault = Material('fastcmd/hud/default.jpg')
local circlemask = Material('fastcmd/hud/circlemask')
local edgedefault = Material('fastcmd/hud/edge.png')
local rotate3d = 10
local cl_fcmd_notify = CreateClientConVar('cl_fcmd_notify', '1', true, false)
------------------------------
local function numdefault(num, default)
	return isnumber(num) and num or default
end

local function trim(str) 
	if not isstring(str) then return '' end
	return str:gsub('^%s+', ''):gsub('%s+$', '') 
end
------------------------------
function FcmdLoadMaterials(path, default)
	-- 加载游戏目录或缓存目录的材质, 加载缓存目录材质
	local prefix1 = string.sub(str, 1, 10)
	local prefix2 = string.sub(str, 1, 6)
	
	if prefix1 == 'materials/' or prefix1 == 'materials\\' then
		return Material(string.sub(path, 11))
	elseif prefix2 == 'cache/' or prefix2 == 'cache\\' then
		-- 失败后使用默认材质
		local mat = AddonMaterial(string.sub(path, 7))
		if mat == nil then
			FcmdWarn('#fcmd.warn.load', '#fcmd.warn.cmat_not_exist')
			return icondefault
		else
			return mat
		end
	else
		return Material(path)
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
	if isstring(wdata.cicon) and wdata.cicon ~= '' then
		rootcache.cicon = FcmdLoadMaterials(wdata.cicon)
	else
		rootcache.cicon = cicondefault
	end
	if isstring(wdata.arrow) and wdata.arrow ~= '' then
		rootcache.arrow = FcmdLoadMaterials(wdata.arrow)
	else
		rootcache.arrow = arrowdefault
	end
	if isstring(wdata.edge) and wdata.edge ~= '' then
		rootcache.edge = FcmdLoadMaterials(wdata.edge)
	else
		rootcache.edge = edgedefault
	end

	---- 变量边界

	-- 比例、角度边界大小
	local angbound = min(
		twopi / max(#wdata.metadata, 1) * max(numdefault(wdata.iconsize, 0.5), 0), 
		ang_120
	)
	
	rootcache.fade = max(numdefault(wdata.fade, 100), 0)
	rootcache.centersize = max(numdefault(wdata.centersize, 0.5), 0)
	rootcache.iconsize = sin(angbound * 0.25) * 2
	rootcache.rotate3d = numdefault(wdata.rotate3d, 10)

	-- 生成位置、加载材质
	local step = twopi / #wdata.metadata
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

		local icon = node.icon
		if isstring(icon) and icon ~= '' then
			nodecache.icon = FcmdLoadMaterials(icon)
		else
			nodecache.icon = icondefault
		end

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
	-- 从文件中获取wheeldata
	if not file.Exists(filepath, 'DATA') then
		FcmdError('#fcmd.err.load', '#fcmd.err.file_not_exist')
		return nil
	end

	local json = file.Read(filepath, 'DATA')	
	return FcmdParseJSON2WheelData(json)
end

function FcmdSaveWheelData(wdata, filepath, override)
	-- 保存wheeldata到文件
	if not override and file.Exists(filepath, 'DATA') then
		FcmdError('#fcmd.err.save', '#fcmd.err.file_exist')
		return false
	end

	local json = FcmdDumpsWheelData2JSON(wdata)
	file.Write(path, json)

	return true
end

function FcmdDelete(filepath)
	-- 删除数据文件

	if not file.Exists(filepath, 'DATA') then
		return true
	end

	file.Delete(filepath)
	return true
end

function FcmdCreateWheelDataFile(dirpath)
	-- 新建wheeldata文件

	-- 检查暂停
	if gui.IsGameUIVisible() then 
		FcmdError('#fcmd.err.create', '#fcmd.err.pause')
		return false
	end

	file.Write(dirpath..'/wnew'..tostring(os.time())..'.json', [[
{
	"autoclip": true,
	"metadata": [
		{
			"call": {
				"pexecute": "test_example \"Hello World\""
			},
			"icon": "fastcmd/hud/world.jpeg"
		},
		{
			"call": {
				"pexecute": "test_example \"Hello Garry's Mod\""
			},
			"icon": "fastcmd/hud/gmod.jpeg"
		},
		{
			"call": {
				"pexecute": "test_example \"Hello Workshop\""
			},
			"icon": "fastcmd/hud/workshop.jpeg"
		}
	]
}
	]])

	return true
end