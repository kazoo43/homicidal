local matindex = {
	["male01"] = 3,
	["male02"] = 2,
	["male03"] = 4,
	["male04"] = 4,
	["male05"] = 4,
	["male06"] = 0,
	["male07"] = 4,
	["male08"] = 0,
	["male09"] = 2,
	["female01"] = 2,
	["female02"] = 3,
	["female03"] = 3,
	["female04"] = 1,
	["female05"] = 2,
	["female06"] = 4,
}

local sex = {
	["male01"] = "male",
	["male02"] = "male",
	["male03"] = "male",
	["male04"] = "male",
	["male05"] = "male",
	["male06"] = "male",
	["male07"] = "male",
	["male08"] = "male",
	["male09"] = "male",
	["female01"] = "female",
	["female02"] = "female",
	["female03"] = "female",
	["female04"] = "female",
	["female05"] = "female",
	["female06"] = "female"
}

-- Keep original accessory coordinates if needed for reference, though we use AccessoryList from shared
local acc_cords = {
	["Green Scarf"]=Vector(0,300,0),
	["Big Red Backpack"]=Vector(50,0,0)
}

net.Receive("accessory",function()
	local ply = net.ReadEntity()
	ply.ModelSex = net.ReadString()
	ply.Accessory = net.ReadString()
	ply.AccessoryModel = nil 
end)

surface.CreateFont("HMCD_Title", {
	font = "Roboto",
	size = 32,
	weight = 1000,
	antialias = true
})

surface.CreateFont("HMCD_Label", {
	font = "Roboto",
	size = 18,
	weight = 500,
	antialias = true
})

local AppearanceMenuOpen, Frame = false, nil

local function OpenMenu(ply)
	if AppearanceMenuOpen then return end
	AppearanceMenuOpen = true
	local ply = LocalPlayer()

	-- Main Frame
	Frame = vgui.Create("DFrame")
	Frame:SetSize(ScrW() * 0.7, ScrH() * 0.8)
	Frame:Center()
	Frame:SetTitle("")
	Frame:MakePopup()
	Frame:ShowCloseButton(true)
	Frame:SetDraggable(true)
	
	Frame.Paint = function(self, w, h)
		draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40, 240))
		draw.RoundedBox(4, 0, 0, w, 30, Color(30, 30, 30, 255))
		draw.SimpleText("Character Customization", "HMCD_Title", 10, 35, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end
	
	Frame.OnClose = function()
		AppearanceMenuOpen = false
	end

	-- Layout
	local ControlPanel = vgui.Create("DPanel", Frame)
	ControlPanel:Dock(LEFT)
	ControlPanel:SetWide(Frame:GetWide() * 0.35)
	ControlPanel:DockMargin(10, 60, 10, 10)
	ControlPanel.Paint = function(self, w, h)
		draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 50, 100))
	end
	
	local PreviewPanel = vgui.Create("DModelPanel", Frame)
	PreviewPanel:Dock(FILL)
	PreviewPanel:DockMargin(0, 60, 10, 10)
	PreviewPanel:SetFOV(50)
	
	-- Controls Scroll
	local Scroll = vgui.Create("DScrollPanel", ControlPanel)
	Scroll:Dock(FILL)
	Scroll:DockMargin(10, 10, 10, 10)

	-- Helper function for labels
	local function AddLabel(text, parent)
		local lbl = vgui.Create("DLabel", parent)
		lbl:SetText(text)
		lbl:SetFont("HMCD_Label")
		lbl:SetColor(Color(200, 200, 200))
		lbl:Dock(TOP)
		lbl:DockMargin(0, 10, 0, 5)
		return lbl
	end

	-- Helper function for combos
	local function AddCombo(parent)
		local cmb = vgui.Create("DComboBox", parent)
		cmb:Dock(TOP)
		cmb:SetTall(25)
		return cmb
	end

	-- Inputs
	AddLabel("Name", Scroll)
	local NameEntry = vgui.Create("DTextEntry", Scroll)
	NameEntry:Dock(TOP)
	NameEntry:SetTall(25)
	NameEntry:SetText(ply:GetNWString("Character_Name", "Unknown"))
	
	AddLabel("Model", Scroll)
	local MdlSelect = AddCombo(Scroll)
	for k, v in pairs(Models_Customize) do
		MdlSelect:AddChoice(v)
	end

	AddLabel("Clothes Style", Scroll)
	local CSelect = AddCombo(Scroll)
	for k, v in pairs(Clothes_Customize) do
		CSelect:AddChoice(v)
	end
	
	AddLabel("Accessory", Scroll)
	local ASelect = AddCombo(Scroll)
	for k, v in pairs(AccessoryList) do
		ASelect:AddChoice(k)
	end

	AddLabel("Clothing Color", Scroll)
	local Mixer = vgui.Create("DColorMixer", Scroll)
	Mixer:Dock(TOP)
	Mixer:SetTall(150)
	Mixer:SetPalette(true)
	Mixer:SetAlphaBar(false)
	Mixer:SetWangs(true)

	AddLabel("Model Rotation", Scroll)
	local RotSlider = vgui.Create("DNumSlider", Scroll)
	RotSlider:Dock(TOP)
	RotSlider:SetMin(-180)
	RotSlider:SetMax(180)
	RotSlider:SetDecimals(0)
	RotSlider:SetValue(45)
	RotSlider:SetDark(false)

	local SaveBtn = vgui.Create("DButton", ControlPanel)
	SaveBtn:Dock(BOTTOM)
	SaveBtn:DockMargin(10, 10, 10, 10)
	SaveBtn:SetTall(40)
	SaveBtn:SetText("Save & Apply")
	SaveBtn:SetFont("HMCD_Label")
	
	-- Load or Randomize Data
	if file.Exists("union_appearance.txt", "DATA") then
		local vartxt = string.Split(file.Read("union_appearance.txt", "DATA"), "\n")
		MdlSelect:SetValue(tostring(vartxt[1]))
		Mixer:SetColor(Color(vartxt[2] * 255, vartxt[3] * 255, vartxt[4] * 255, 255))
		CSelect:SetValue(tostring(vartxt[5]))
		NameEntry:SetValue(tostring(vartxt[6]))
		-- NamePers (visual label) logic removed as redundant
		local loadedAcc = tostring(vartxt[8])
		if not AccessoryList[loadedAcc] then loadedAcc = "none" end
		ASelect:SetValue(loadedAcc)
	else
		local rndModel = table.Random(Models_Customize)
		local rndClothes = table.Random(Clothes_Customize)
		local rndAcc = "none"
		
		MdlSelect:SetValue(rndModel)
		CSelect:SetValue(rndClothes)
		ASelect:SetValue(rndAcc)
		Mixer:SetColor(Color(math.random(0,255), math.random(0,255), math.random(0,255), 255))
	end

	-- Update Function
	local function UpdatePreview()
		local mdlName = MdlSelect:GetValue()
		local clothes = CSelect:GetValue()
		local col = Mixer:GetColor()
		
		if not mdlName or mdlName == "Model" then return end
		
		local trueModel = player_manager.TranslatePlayerModel(mdlName)
		util.PrecacheModel(trueModel)
		PreviewPanel:SetModel(trueModel)
		
		local ent = PreviewPanel.Entity
		if not IsValid(ent) then return end
		
		-- Reset Submaterials
		ent:SetSubMaterial()
		
		-- Apply Clothes
		if clothes ~= "Style Clothes" and matindex[mdlName] and sex[mdlName] then
			ent:SetSubMaterial(matindex[mdlName], "models/humans/" .. sex[mdlName] .. "/group01/" .. clothes)
		end
		
		-- Apply Color
		local vec = Vector(col.r/255, col.g/255, col.b/255)
		ent.GetPlayerColor = function() return vec end
		
		-- Setup Accessory Rendering
		local accName = ASelect:GetValue()
		ent.AccData = nil
		if accName and accName ~= "Accessory" and AccessoryList[accName] then
			local accInfo = AccessoryList[accName]
			if accInfo[1] then
				-- Store data for PostDrawModel
				ent.AccData = {
					Model = accInfo[1],
					Bone = accInfo[2],
					Info = (sex[mdlName] == "male") and accInfo[3] or accInfo[4],
					Skin = accInfo[6] or 0
				}
			end
		end
	end

	-- Event Handlers
	MdlSelect.OnSelect = UpdatePreview
	CSelect.OnSelect = UpdatePreview
	ASelect.OnSelect = UpdatePreview
	Mixer.ValueChanged = UpdatePreview

	-- Initial Update
	UpdatePreview()
	
	-- Rotation Logic
	function PreviewPanel:LayoutEntity(ent)
		ent:SetAngles(Angle(0, RotSlider:GetValue(), 0))
		ent:SetSequence(ent:LookupSequence("idle_all_01"))
		if ( ent:GetCycle() >= 1 ) then ent:SetCycle( 0 ) end
		self:RunAnimation()
	end
	
	-- Custom Accessory Rendering
	function PreviewPanel:PostDrawModel(ent)
		if not ent.AccData then return end
		local data = ent.AccData
		
		if not IsValid(ent.AccModel) then
			ent.AccModel = ClientsideModel(data.Model)
			ent.AccModel:SetNoDraw(true)
		end
		
		local acc = ent.AccModel
		if not IsValid(acc) then return end
		
		if acc:GetModel() ~= data.Model then
			acc:SetModel(data.Model)
		end
		
		acc:SetSkin(data.Skin)
		
		local boneID = ent:LookupBone(data.Bone)
		if not boneID then return end
		
		local pos, ang = ent:GetBonePosition(boneID)
		if not pos then return end
		
		local posInfo = data.Info -- {Vector(offset), Angle(offset), Scale}
		local offsetVec = posInfo[1]
		local offsetAng = posInfo[2]
		local scale = posInfo[3]
		
		-- Calculate Position (Right * x + Forward * y + Up * z)
		local newPos = pos + ang:Right() * offsetVec.x + ang:Forward() * offsetVec.y + ang:Up() * offsetVec.z
		
		-- Calculate Angles
		ang:RotateAroundAxis(ang:Right(), offsetAng.p)
		ang:RotateAroundAxis(ang:Up(), offsetAng.y)
		ang:RotateAroundAxis(ang:Forward(), offsetAng.r)
		
		acc:SetRenderOrigin(newPos)
		acc:SetRenderAngles(ang)
		
		local mat = Matrix()
		mat:Scale(Vector(scale, scale, scale))
		acc:EnableMatrix("RenderMultiply", mat)
		
		acc:DrawModel()
	end
	
	-- Cleanup accessory on panel removal
	PreviewPanel.OnRemove = function(self)
		if IsValid(self.Entity) and IsValid(self.Entity.AccModel) then
			self.Entity.AccModel:Remove()
		end
	end

	SaveBtn.DoClick = function()
		local Maudel = MdlSelect:GetValue()
		local col = Mixer:GetColor()
		local R, G, B = col.r / 255, col.g / 255, col.b / 255
		local Clothes = CSelect:GetValue()
		local BystName = NameEntry:GetValue()
		local rost = 1 -- Default height/scale
		local Accs = ASelect:GetValue()
		
		RunConsoleCommand("customize_manual", Maudel, R, G, B, Clothes, BystName, rost, Accs)
		
		local RawData = tostring(Maudel) .. "\n" .. tostring(R) .. "\n" .. tostring(G) .. "\n" .. tostring(B) .. "\n" .. tostring(Clothes) .. "\n" .. tostring(BystName) .. "\n" .. tostring(rost) .. "\n" .. tostring(Accs)
		file.Write("union_appearance.txt", RawData)
		
		Frame:Close()
	end
end

net.Receive("open_appmenu",function()
	OpenMenu()
end)
