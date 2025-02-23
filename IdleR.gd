extends Node

func _parse_supply_data(file: Array[String]) -> Array[Supply]:
	var supplies: Array[Supply]
	var supplyStringArray = file[0].split(",")
	for str in supplyStringArray:
		var sup: Supply
		var name: String
		var amount: int = 0
		if "." in str:
			name = str.split(".")[0].rstrip("\r")
			amount = int(str.split(".")[1])
		else:
			name = str.rstrip("\r")
		sup = Supply.new(name)
		sup.mod_quant(amount)
		supplies.append(sup)
	return supplies
	
func _parse_factor_data(file: Array[String], supplies: Array[Supply]) -> Array[Factor]:
	var factors: Array[Factor]
	for i in range(1, file.size()):
		if !file[i].is_empty():
			var factorAsArray = file[i].split(";")
			var factorName = factorAsArray[0]
			var factorCost = _parse_delta_data(factorAsArray[1], supplies)
			var factorCon = _parse_delta_data(factorAsArray[2], supplies)
			var factorProd = _parse_delta_data(factorAsArray[3], supplies)
			var factorDesc = factorAsArray[4]
			
			var factor = Factor.new(factorName, factorCost)
			factor.consume = factorCon
			factor.produce = factorProd
			factor.desc = factorDesc
			factors.append(factor)
	return factors

func _parse_delta_data(data: String, supplies: Array[Supply]) -> Array[Delta]:
	var deltas: Array[Delta]
	var supplyNames: Array[String]
	for sup in supplies:
		supplyNames.append(sup.name)
	var deltaDataAsArray = data.split(",")
	for datum in deltaDataAsArray:
		if !datum.is_empty():
			var delta: Delta
			var deltaParsed = datum.split(".")
			var deltaName = deltaParsed[0]
			if deltaName not in supplyNames:
				print("ERROR: " + datum + " - Supply " + deltaName + " not in Supplies!")
			else:
				var index = supplyNames.find(deltaName)
				var deltaAmt = deltaParsed[1]
				if deltaParsed[1].begins_with("R"):
					#parse as random
					delta = _parse_RNGdelta(supplies[index], deltaAmt)
				else:
					#parse as constant
					deltaAmt = int(deltaParsed[1])
					delta = Delta.new(supplies[index], deltaAmt)
				deltas.append(delta)
	return deltas

func _parse_RNGdelta(supply: Supply, RNG: String) -> Delta:
	var delta: Delta
	var quant: int
	var val: int
	var offset: int = 0
	
	var removeR = RNG.split("R")[1]
	#get quant
	var quantString = removeR.split("d")[0]
	if quantString.begins_with("-"):
		var quantStringMag = quantString.lstrip("-")
		quant = -int(quantStringMag)
	else:
		quant = int(quantString)
	#get val & offset
	var rightString = removeR.split("d")[1]
	var rightParsed
	if ("+" in rightString):
		rightParsed = rightString.split("+")
		val = int(rightParsed[0])
		offset = int(rightParsed[1])
	elif ("-" in rightString):
		rightParsed = rightString.split("-")
		val = int(rightParsed[0])
		offset = -int(rightParsed[1])
	else:
		val = int(rightString)
	delta = Delta.new(supply, 0, quant, val, offset)
	return delta

class factorCard extends PanelContainer:
	var factor: Factor
	var buyButton: Button
	var sellButton: Button
	var quantLabel: Label
	
	func _init(factor: Factor):
		self.factor = factor
		
		var margCont = MarginContainer.new()
		var margin_value = 20
		margCont.add_theme_constant_override("margin_top", margin_value)
		margCont.add_theme_constant_override("margin_left", margin_value)
		margCont.add_theme_constant_override("margin_bottom", margin_value)
		margCont.add_theme_constant_override("margin_right", margin_value)
		var gridCont = GridContainer.new()
		var hBoxLabels = HBoxContainer.new()
		var hBoxButtons = HBoxContainer.new()
		var vBoxMain = VBoxContainer.new()
		var vBoxLabels = VBoxContainer.new()
		
		var nameLabel = Label.new()
		nameLabel.text = str(factor.name)
		var descLabel = Label.new()
		descLabel.text = str(factor.desc)
		var costLabel = Label.new()
		costLabel.text = factor.deltaAsString(factor.cost)
		self.buyButton = Button.new()
		buyButton.text = "Buy"
		self.quantLabel = Label.new()
		quantLabel.text = str(factor.quant)
		quantLabel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		self.sellButton = Button.new()
		sellButton.text = "Sell"
		sellButton.size_flags_horizontal = Control.SIZE_SHRINK_END
		
		vBoxLabels.add_child(nameLabel)
		vBoxLabels.add_child(descLabel)
		vBoxLabels.add_child(costLabel)
		
		hBoxLabels.add_child(vBoxLabels)
		hBoxLabels.add_child(quantLabel)
		
		hBoxButtons.add_child(buyButton)
		hBoxButtons.add_child(sellButton)
		
		vBoxMain.add_child(hBoxLabels)
		vBoxMain.add_child(hBoxButtons)
		
		gridCont.add_child(vBoxMain)
		
		margCont.add_child(gridCont)
		
		self.add_child(margCont)
	
	func buy(quant: int):
		self.factor.buy(quant)
		self.quantLabel.text = str(self.factor.quant)
	
	func sell(quant: int):
		self.factor.sell(quant)
		self.quantLabel.text = str(self.factor.quant)

class supplyCard extends HBoxContainer:
	var supply: Supply
	var nameLabel: Label
	var amtLabel: Label
	
	func _init(supply: Supply):
		self.supply = supply
		self.nameLabel = Label.new()
		nameLabel.text = str(self.supply.name)
		self.amtLabel = Label.new()
		amtLabel.text = str(self.supply.quant)
		self.add_child(nameLabel)
		self.add_child(amtLabel)
	
	func update():
		amtLabel.text = str(supply.quant)
	
	static func toSupplyCardArray(supArray: Array[Supply]) -> Array[supplyCard]:
		var supCardArray: Array[supplyCard]
		for s in supArray:
			var supCard = supplyCard.new(s)
			supCardArray.append(supCard)
		return supCardArray

##Refactored IdleR API Java code to GDScript

# Supply class
class Supply:
	var name: String = ""
	var desc: String = ""
	var max: int = 0:
		set(value):
			if value > min:
				has_max = true
				max = value
			else:
				print("%s's max cannot be lower than min" % name)
	var min: int = 0:
		set(value):
			if has_max:
				if value > max:
					print("%s's min cannot be higher than max" % name)
				else:
					min = value
			else:
				min = value
	var quant: int = 0:
		set(value):
			if has_max and value > max:
				quant = max
			elif value < min:
				quant = min
			else:
				quant = value
	var lock: bool = false
	var has_max: bool = false

	# Constructor
	func _init(name: String, lock: bool = false, has_max: bool = false):
		self.name = name
		self.desc = ""
		self.min = 0
		self.has_max = has_max
		self.quant = 0
		self.lock = lock

	# Modify quantity
	func mod_quant(amount: int):
		self.quant += amount

# Delta class
class Delta:
	var sup: Supply
	var quant: int = 0
	var diceQuant: int = 0:
		set(value):
			diceQuant = value
			if (diceQuant != 0) && (diceVal != 0):
				is_variable = true
	var diceVal: int = 0:
		set(value):
			if value < 0:
				print("ERROR: diceVal cannot be less than 0!")
			else:
				diceVal = value
				if (diceQuant != 0) && (diceVal != 0):
					is_variable = true
	var diceOffset: int = 0
	var is_variable: bool = false

	# Constructor
	func _init(sup: Supply, quant: int, diceQuant: int = 0, diceVal: int = 0, diceOffset: int = 0):
		self.sup = sup
		self.quant = quant
		self.diceQuant = diceQuant
		self.diceVal = diceVal
		self.diceOffset = diceOffset
	
	func rollQuant():
		if is_variable:
			var RNG = RandomNumberGenerator.new()
			var total: int = 0
			var count: int
			var dir: int = 1
			if self.diceQuant<0:
				count = -self.diceQuant
				dir = -1
			else:
				count = self.diceQuant
			for i in range(count):
				total += dir * RNG.randi_range(1, self.diceVal)
			total += self.diceOffset
			self.quant = total
	
	func toStr() -> String:
		var s: String
		if is_variable:
			var sign: String
			if diceOffset >= 0:
				sign = "+"
			else:
				sign = ""
			s = str(diceQuant) + "d" + str(diceVal) + sign + str(diceOffset) + " " + str(sup.name) + "s"
			
		else:
			s = str(quant) + " " + str(sup.name)
			if quant != 1:
				s = s + "s"
		return s

# Factor class
class Factor:
	var name: String = ""
	var desc: String = ""
	var cost: Array[Delta] = []
	var produce: Array[Delta] = []:
		set(value):
			has_prod = true
			produce = value
	var consume: Array[Delta] = []:
		set(value):
			has_con = true
			consume = value
	var quant: int = 0
	var sell_factor: float = 0.5
	var has_prod: bool = false
	var has_con: bool = false
	var can_sell: bool = false
	var lock: bool = false

	# Constructor
	func _init(name: String, cost: Array[Delta], can_sell: bool = true, lock: bool = false):
		self.name = name
		self.desc = ""
		self.cost = cost
		self.quant = 0
		self.sell_factor = 0.5
		self.has_con = false
		self.has_prod = false
		self.can_sell = can_sell
		self.lock = lock

	# Methods
	func convert():
		for _i in range(quant):
			var can_afford = true
			if has_con:
				can_afford = false
				var go_count = 0
				for delta in consume:
					delta.rollQuant()
					if delta.sup.quant >= delta.quant:
						go_count += 1
				if go_count == consume.size():
					can_afford = true
					for delta in consume:
						delta.sup.mod_quant(-delta.quant)
			if can_afford and has_prod:
				for delta in produce:
					delta.rollQuant()
					delta.sup.mod_quant(delta.quant)

	func buy(amount: int):
		if amount > 0:
			var go_count = 0
			for cost_item in cost:
				if cost_item.sup.quant >= cost_item.quant * amount:
					go_count += 1
			if go_count == cost.size():
				for cost_item in cost:
					cost_item.sup.mod_quant(-cost_item.quant * amount)
				quant += amount

	func sell(amount: int):
		if amount <= quant and can_sell:
			for cost_item in cost:
				cost_item.sup.mod_quant(int(cost_item.quant * amount * sell_factor))
			quant -= amount
	
	func deltaAsString(dArray: Array[Delta]) -> String:
		var s: String
		for i in range(len(dArray)):
			if i > 0:
				s += ", "
			s += dArray[i].toStr()
		return s

#NOTE: Upgrade is not implemented

# Upgrade class
class Upgrade:
	var name: String = ""
	var desc: String = ""
	var cost: int = 0
	var lock: bool = false

	# Constructor
	func _init(name: String, desc: String, cost: int, lock: bool = false):
		self.name = name
		self.desc = desc
		self.cost = cost
		self.lock = lock
