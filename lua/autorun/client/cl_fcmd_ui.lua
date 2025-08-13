
local Background = Color(107, 110, 114, 200)
local default_name = 'hud/cmdmenu/default.png'



local EditorPanel = {}


function EditorPanel:Init()
    self:SetPos(0, 25)
    local width,height = self:GetSize()
    local x,label_x = 120,10
    local y,label_y = 20,23
    local w,h = 100,20
    AddMenuText(CMDMENU_TEXT.After_choose[sv_zmlan],label_x,label_y,self)
    self.acmd = vgui.Create( 'DTextEntry', self )//指令框
    self.acmd:SetPos(x, y)
    self.acmd:SetSize( w, h )
    y,label_y = y + 40,label_y + 40

    AddMenuText(CMDMENU_TEXT.BorR[sv_zmlan],label_x,label_y,self)
    self.button = vgui.Create( 'DButton', self )//执行或绑定选择
    self.button:SetPos(x, y)
    self.button:SetSize( w, h )
    self.button:SetText( CMDMENU_TEXT.Run[sv_zmlan] )
    self.button.run = true
    self.button.DoClick = function()
        self.button.run = !self.button.run
        self.button:SetText( self.button.run and CMDMENU_TEXT.Run[sv_zmlan] or CMDMENU_TEXT.Bind[sv_zmlan] )
        LocalPlayer():EmitSound(Sound(self.button.run and 'Buttons.snd3' or 'Buttons.snd2'), 75,100) 
    end
    y,label_y = y + 40,label_y + 40

    AddMenuText(CMDMENU_TEXT.icon[sv_zmlan],label_x,label_y,self)
    self.ctrl = vgui.Create( 'ControlPresets', self )//预设图标
    self.ctrl:SetPos(x, y)
    self.ctrl:SetSize( w, h )
    self.ctrl:SetPreset('1')
    self.ctrl:AddConVar('cl_cm_path')
    self.ctrl.OnSelect = function(a,b,index,cmd) 
        if presetIMG[index] then
            self.path:SetText(presetIMG[index])    
        else
            if istable(cmd) then self.path:SetText(cmd['cl_cm_path'] or '') end 
        end
        self.path.Update()
    end
    for k, v in pairs(presetIMG) do self.ctrl:AddOption(k) end
    y,label_y = y + 40,label_y + 40

    AddMenuText(CMDMENU_TEXT.Path[sv_zmlan],label_x,label_y,self)
    self.path = vgui.Create( 'DTextEntry', self )//图标路径
    self.path:SetPos(x, y)
    self.path:SetSize( w, h )
    self.path.Update = function()
        local string = self.path:GetText()
        LocalPlayer():ConCommand('cl_cm_path '..string)
        if string == '' then string = default_name end
        self.material:SetImage(string) 
    end
    self.path.OnChange = function(self) self.Update() end
    y,label_y = y + 40,label_y + 40

    self.material = vgui.Create( 'DImage', self )//图标预览
    self.material:SetPos(65, y)
    self.material:SetSize( w, w )
    y,label_y = y + 120,label_y + 120

    self.apply = vgui.Create( 'DButton', self )//应用按钮
    self.apply:SetPos((width - w)*0.5, y)
    self.apply:SetSize( w, 2*h )
    self.apply:SetText( CMDMENU_TEXT.Apply[sv_zmlan] )
end

function EditorPanel:Paint() 
    draw.RoundedBox(6, 0, 0, self:GetWide(), self:GetTall(), Background)
end
vgui.Register('EditorPanel', EditorPanel, 'DPanel')


