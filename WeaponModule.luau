--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local textChanger = ReplicatedStorage.TextChange

local Weapons = {}
Weapons.__index = Weapons

export type Weapon = {
	Damage: number,
	Name: string,
	Cooldown: number,
	OnDestroy : any,
	
	IsEquipped : boolean,
	IsOnCooldown: boolean,
	
	AvaliableFireModes: {string},
	FireMode: string,
	
	MaxBulletAmount: number,
	CurrentBulletAmount: number,

	MaxBulletAmountInOneMag: number,
	CurrentBulletAmountInMag: number,
	
	Equip: (self: Weapon) -> (),
	Shoot: (self: Weapon) -> (),
	Reload: (self: Weapon) -> (),
	UnEquip: (self: Weapon) -> (),
	GetMoreAmmo: (self: Weapon, AmmoAmount : number) -> (),
	SetFireMode: (self: Weapon, Mode : string) -> (),
}

local alreadyHit = {}


local function CheckFireModeAndAddCoolDown(data)
	if data.FireMode == "Auto" then
		data.IsOnCooldown = true
		task.wait(data.Cooldown)
		data.IsOnCooldown = false
	elseif data.FireMode == "Semi"then
		data.IsOnCooldown = true
		task.wait(data.Cooldown / 2)
		data.IsOnCooldown = false
	end
end

function Weapons.new(damage: number,name: string,cooldown: number,maxBulletAmount: number): Weapon
	local self = setmetatable({}, Weapons)
	--Main values
	self.Damage = damage
	self.Name = name
	self.Cooldown = cooldown
	
	--Booleans
	self.IsEquipped = false
	self.IsOnCooldown = false
	
	--Numbers
	self.MaxBulletAmount = maxBulletAmount
	self.CurrentBulletAmount = maxBulletAmount
	self.MaxBulletAmountInOneMag = 10
	self.CurrentBulletAmountInMag = 10
	
	--FireModes
	self.AvaliableFireModes = {"Auto", "Semi"}
	self.FireMode = "Auto"
	
	--Events
	self._Destroy = Instance.new("BindableEvent")
	self.OnDestroy = self._Destroy.Event
	
	return self
end

function Weapons:GetMoreAmmo(AmmoAmount: number)
	if self.CurrentBulletAmount < self.MaxBulletAmount and (self.CurrentBulletAmount + AmmoAmount) <= self.MaxBulletAmount then
		self.CurrentBulletAmount += AmmoAmount
		print("Got more bullets, current bullet amount", self.CurrentBulletAmount)
	end
end

function Weapons:SetFireMode(mode:string)
	if table.find(self.AvaliableFireModes, mode) then
		print("Mode found and changing to:", mode)
		self.FireMode = mode
	end
end

function Weapons:UnEquip()
	if not self.IsEquipped then 
		print("Gun is already not Equipped")
		return 
	end
	if self.IsEquipped then 
		print(self.Name, "UnEquipped")
		self.IsEquipped = false
	end
end

function Weapons:Equip()
	if self.IsEquipped then return end
	if not self.IsEquipped then
		textChanger:FireAllClients(self.Name, "Equipped,you can now Shoot")
		print(self.Name, "Equipped,you can now Shoot")
		self.IsEquipped = true
	end
end

function Weapons:Shoot(player : Player)
	if not self.IsEquipped then
		textChanger:FireAllClients("Gun is not equipped, Please equip Gun", self.Name)
		warn("Gun is not equipped, Please equip Gun", self.Name)
		return
	end
	if self.IsOnCooldown then
		warn(self.Name,"is on cooldown")
		return
	end
	if self.CurrentBulletAmount <= 0 then
		print("Out of ammo!")
		if not Weapons then return end
		print("Gun data for: ", data.Name, "Destroyed")
		self.OnDestroy:Fire()
		Weapons = nil
		return
	end

	if self.CurrentBulletAmountInMag <= 0 then
		print("Magazine empty. Reloading...")
		self:Reload()

		if self.CurrentBulletAmountInMag <= 0 then
			return
		end
	end

	self.CurrentBulletAmount -= 1
	self.CurrentBulletAmountInMag -= 1

	print(string.format("Shot Fire mode:("..self.FireMode.. ")! Magazine: %d/%d | Total: %d",self.CurrentBulletAmountInMag,self.MaxBulletAmountInOneMag,self.CurrentBulletAmount))
	textChanger:FireAllClients(string.format("Shot Fire mode:("..self.FireMode.. ")! Magazine: %d/%d | Total: %d",self.CurrentBulletAmountInMag,self.MaxBulletAmountInOneMag,self.CurrentBulletAmount))
	if player then
		local playerCharacter = player.Character
		local toolModel: Tool = playerCharacter:FindFirstChildWhichIsA("Tool")
		if toolModel then
			local origin = toolModel:GetPivot().Position
			local direction = toolModel:GetPivot().LookVector * 1000
			local raycastParams = RaycastParams.new()
			raycastParams.FilterType = Enum.FilterType.Exclude
			raycastParams.FilterDescendantsInstances = {playerCharacter, toolModel}
			while toolModel.Parent do
				local hitParts = workspace:Raycast(origin, direction, raycastParams)
				if hitParts then
					if hitParts.Instance.Parent:IsA("Model") then
						if alreadyHit[hitParts.Instance.Parent.Name]then
							return
						end
						local humanoid = hitParts.Instance.Parent:FindFirstChildWhichIsA("Humanoid")
						if humanoid and not alreadyHit[hitParts.Instance.Parent.Name] then
							humanoid:TakeDamage(self.Damage)
							print("Damaged",  hitParts.Instance.Parent.Name, "For", self.Damage)
							alreadyHit[hitParts.Instance.Parent.Name] = true
						end
					end
				end
				task.wait(0)
			end

		end
	end
	
	
	CheckFireModeAndAddCoolDown(self)

end

function Weapons:Reload()
	if self.CurrentBulletAmount <= 0 then
		if not Weapons then return end
		textChanger:FireAllClients("Gun data for: ", data.Name, "Destroyed")
		print("Gun data for: ", data.Name, "Destroyed")
		self.OnDestroy:Fire()
		Weapons = nil
		return
	end

	self.CurrentBulletAmountInMag = 10

	print("Reloaded!")
	textChanger:FireAllClients("Reloaded!")
end


return Weapons