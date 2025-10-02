local function strdefault(str, default)
	return isstring(str) and str or default
end

local function numdefault(num, default)
	return isnumber(num) and num or default
end

function FcmduCreateCustomGrid(parent, layout)
    -- 固定行高、自动行间距、自动列宽
	-- 并不支持大量添加控件, 代价是O(n^2)
    local Grid = vgui.Create('DPanel', parent)

	function Grid:SetLayout(layout)
		layout = istable(layout) and layout or {}
		layout.row = math.max(layout.row or 3, 1)
		layout.col = math.max(layout.col or 3, 1)
		layout.paddingw = math.max(layout.paddingw or 10, 0)
		layout.h = math.max(layout.h or 20, 1)
		self.layout = layout
	end

	Grid:SetLayout(layout)
	Grid.childs = {}

    function Grid:AddItem(child)
		if #self.childs >= self.layout.row * self.layout.col then return end
		table.insert(self.childs, child)
		self:RefreshLayout()
    end

	function Grid:OnSizeChanged(nw, nh)
		local layout = self.layout
        local row = layout.row 
        local col = layout.col
		local paddingw = layout.paddingw
		local unith = layout.h
        
	    local unitw = math.max(
			(nw - paddingw * (col + 1)) / col,
			1
		)

        local paddingh =  math.max(
			(nh - unith * row) / (row + 1),
			0
		)

        for i, child in ipairs(self.childs) do
			local temp = (i - 1) % row
			local x, y = ((i - 1) - temp) / row, temp  
			
            child:SetPos(
                unitw * x + (x + 1) * paddingw, 
                unith * y + (y + 1) * paddingh
            )
            child:SetSize(unitw, unith)
        end
    end

	function Grid:RefreshLayout() 
		self:OnSizeChanged(self:GetWide(), self:GetTall())
	end

    function Grid:Paint() end

    return Grid
end

function FcmduCreateCustomList(parent, paddingw, paddingh)
	-- 单行列表, 每个控件分配一定比例
	-- 并不支持大量添加控件, 代价是O(n^2)
	local List = vgui.Create('DPanel', parent)

	List.paddingw = math.max(paddingw or 0, 0)
	List.paddingh = math.max(paddingh or 0, 0)

	List.layout = {}
	List.childs = {}

    function List:AddItem(child, ratio)
		ratio = ratio or 0.25
		table.insert(self.layout, ratio)
		table.insert(self.childs, child)
		self:RefreshLayout()
    end

	function List:OnSizeChanged(nw, nh)
		local layout = self.layout
		local childs = self.childs

		local paddingw = self.paddingw
		local paddingh = self.paddingh

		nw = math.max(
			nw - paddingw * (#childs + 1),
			1
		)

		nh = math.max(
			nh - paddingh * 2,
			1
		)

		local y = paddingh
		local h = nh

		for i, child in ipairs(childs) do
			local w = math.max(
				nw * layout[i],
				1
			)
			child:SetSize(
				w,
				h
			)
		end

		for i, child in ipairs(childs) do
			local offset = 0
			for j = 1, i - 1 do
				offset = offset + layout[j]
			end

			local x = paddingw * i + offset * nw
			child:SetPos(
				x,
				y
			)
		end
	end

	function List:RefreshLayout()
		self:OnSizeChanged(self:GetWide(), self:GetTall())
	end

	return List
end

function FcmduCreateAdvancedInput(txt, txtbtn, parent, layout)
	-- 高级输入框
	-- 包含输入框、按钮、标签
	local Body = FcmduCreateCustomList(parent, 5, 0)
	local label = vgui.Create('DLabel', Body)
	local TextEntry = vgui.Create('DTextEntry', Body)
	local Button = vgui.Create('DButton', Body)

	
	label:SetText(txt)
	Button:SetText(txtbtn)

	Body.layout = layout or {0.3, 0.5, 0.2}
	Body.childs = {label, TextEntry, Button}
	Body:SetSize(180, 20)
	

	Button.DoClick = function()	
		if isfunction(Body.DoClick) then
			Body:DoClick()
		end
	end

	function TextEntry:OnValueChange(value)
		if isfunction(Body.OnValueChange) then
			Body:OnValueChange(value)
		end
	end

	function Body:SetValue(value)
		TextEntry:SetValue(value)
	end	
	
	function Body:GetValue()
		return TextEntry:GetValue()
	end

	function Body:SetText(txt)
		label:SetText(txt)
	end

	function Body:SetButtonText(txt)
		Button:SetText(txt)
	end

	function Body:SetUpdateOnType(updateOnType)
		TextEntry:SetUpdateOnType(updateOnType)
	end

	TextEntry:SetUpdateOnType(true)
	Body.Paint = function() end

	return Body
end

function FcmduCreateNumSlider(txt, parent, minv, maxv, decimals)
	local slider = vgui.Create('DNumSlider', parent)
    slider:SetMin(minv or 0)
    slider:SetMax(maxv or 100)
    slider:SetDecimals(decimals or 0)
    slider:SetSize(200, 20)
    slider:SetText(txt)
	return slider
end

function FcmduCreateTextEntry(txt, parent)
	-- 带标签的输入框
	local Body = FcmduCreateAdvancedInput(txt, '', parent)
	Body.childs[3]:Remove()
	Body.childs = {Body.childs[1], Body.childs[2]}
	Body.layout = {0.3, 0.7}
	Body:SetSize(180, 20)
	return Body
end

function FcmduCreateBoolenButton(txttrue, txtfalse, parent)
	-- 状态切换按钮
	local Button = vgui.Create('DButton', parent)

	Button.txttrue = txttrue
	Button.txtfalse = txtfalse

	function Button:SetState(state)
		self.state = state
		if state then
			self:SetText(self.txttrue)
		else
			self:SetText(self.txtfalse)
		end
	end

	function Button:DoClick()
		local state = not self.state
		self:SetState(state)
		if isfunction(self.Trigger) then
			self:Trigger(state)
		end
	end
	
	return Button
end

function FcmduPushPullInput(txt, txtshow, txthide, parent)
	local Body = FcmduCreateAdvancedInput(txt, '', parent)

	Body.txtshow = txtshow
	Body.txthide = txthide

	function Body:SetExpand(state)
		self.expand = state
		if state then
			self:SetButtonText(self.txthide)
			self.layout[2] = 0.5
			self.layout[3] = 1 - self.layout[1] - self.layout[2]
			self.childs[2]:SetVisible(true)
		else
			self:SetButtonText(self.txtshow)
			self.layout[2] = 0
			self.layout[3] = 1 - self.layout[1] - self.layout[2]
			self.childs[2]:SetVisible(false)
		end

		self:RefreshLayout()
	end

	function Body:DoClick()
		local state = not self.expand
		self:SetExpand(state)
		if isfunction(self.Trigger) then
			self:Trigger(state)
		end
	end

	return Body
end

function FcmduCreateSoundInput(txt, parent)
	local Body = FcmduCreateAdvancedInput(txt, '#fcmdu.browse', parent)
	local SoundsBrowser
	function Body:DoClick()	
		SoundsBrowser = FcmduOpenSoundsBrowser()
		local openfolder = string.GetPathFromFilename(Body:GetValue())
		if openfolder and string.Trim(openfolder) ~= '' then 
			SoundsBrowser:SetCurrentFolder(openfolder) 
		end
		function SoundsBrowser:OnSelect(file)
			Body:SetValue(file)
		end
	end

	function Body:OnRemove()
		if IsValid(SoundsBrowser) then SoundsBrowser:Remove() end
	end

	return Body
end

function FcmduCreateMaterialInput(txt, parent)
	local Body = FcmduCreateAdvancedInput(txt, '#fcmdu.browse', parent)
	local MaterialsBrowser
	function Body:DoClick()	
		MaterialsBrowser = FcmduOpenMaterialsBrowser()
		local openfolder = string.GetPathFromFilename(Body:GetValue())
		if openfolder and string.Trim(openfolder) ~= '' then MaterialsBrowser:SetCurrentFolder(openfolder) end
		function MaterialsBrowser:OnSelect(file, mat)
			Body.mat = mat
			Body:SetValue(file)
		end
	end

	function Body:OnRemove()
		if IsValid(MaterialsBrowser) then MaterialsBrowser:Remove() end
	end

	return Body
end


function FcmduCmdInput(txt, parent)
	local Body = FcmduCreateAdvancedInput(txt, '#fcmdu.debug', parent)

	function Body:DoClick()
		FcmdExecuteCmd(Body:GetValue(), FcmdFilter)
	end

	return Body
end

function FcmduCmdInput2(txt, parent, origin)
	-- 带有自动解析功能
	local Body = FcmduCreateAdvancedInput(txt, '', parent) 
	local DebugBtn = vgui.Create('DButton', Body)
	
	Body.layout = {0.2, 0, 0.6, 0.2}
	Body.childs = {Body.childs[1], Body.childs[2], Body.childs[3], DebugBtn}
	Body:RefreshLayout()

	DebugBtn:SetText('#fcmdu.debug')

	local SetTextValue = Body.SetValue
	function Body:SetValue(value)
		if isstring(value) then
			SetTextValue(self, value)
			self:SetExpand(true)
		else
			self:SetExpand(false)
		end
	end	

	local GetTextValue = Body.GetValue
	function Body:GetValue()
		if self.expand then
			return GetTextValue(self)
		else
			return nil
		end
	end

	function Body:SetExpand(state)
		self.expand = state
		if state then
			self:SetButtonText('#fcmdu.auto')
			self.layout[2] = 0.4
			self.childs[2]:SetVisible(true)

			self.layout[3] = 0.2
		else
			self:SetButtonText('#fcmdu.manual')
			self.layout[2] = 0
			self.childs[2]:SetVisible(false)

			self.layout[3] = 0.6
			if isfunction(self.OnValueChange) then self:OnValueChange(nil) end
		end

		self:RefreshLayout()
	end

	function DebugBtn:DoClick()
		if Body.expand then
			FcmdExecuteCmd(GetTextValue(Body), FcmdFilter)
		elseif IsValid(origin) then  
			FcmdExecuteCmd(FcmdAutoParseRexecute(origin:GetValue()), FcmdFilter)
		end
	end

	function Body:DoClick()
		local state = not self.expand
		self:SetExpand(state)
		if isfunction(self.Trigger) then
			self:Trigger(state)
		end
	end

	return Body
end


// local frame = vgui.Create('DFrame')
// frame:SetTitle('测试')
// frame:SetSize(200, 200)
// frame:Center()
// frame:SetSizable(true)
// frame:MakePopup()
// frame:SetDeleteOnClose(true)

// local input = FcmduCreateMaterialInput('测试1', frame)

// input:Dock(FILL)
// function input:OnValueChange(value)
// 	print(value)
// end
// function input:DoClick()
// 	print('fuck')
// end