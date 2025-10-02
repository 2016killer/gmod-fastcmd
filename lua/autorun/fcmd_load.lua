flist1 = file.Find('fcmd/core/*.lua', 'LUA')
flist2 = file.Find('fcmd/ui/*.lua', 'LUA')
for _, filename in pairs(flist1) do
	if SERVER then
		AddCSLuaFile('fcmd/core/' .. filename)
	else
		include('fcmd/core/' .. filename)
	end
end

for _, filename in pairs(flist2) do
	if SERVER then
		AddCSLuaFile('fcmd/ui/' .. filename)
	else
		include('fcmd/ui/' .. filename)
	end
end
