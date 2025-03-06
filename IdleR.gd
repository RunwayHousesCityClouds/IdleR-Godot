extends Node

func _parse_game_data(file: Array[String]) -> Dictionary:
	var flows: Array[Flow]
	var factorIndex: int
	
	#parse Supply flows, add to master list
	flows = _parse_supply_data(file)
	factorIndex = flows.size()
	
	#parse Factor names, add to master list
	for i in range(1, file.size()):
		if !file[i].is_empty():
			var factorAsArray = file[i].split(";")
			var factorName = factorAsArray[0]
			var factor = Flow.new(factorName)
			flows.append(factor)
	
	#finish Factor flows
	for i in range(1, file.size()):
		if !file[i].is_empty():
			var factorAsArray = file[i].split(";")
			var factorCost = _parse_delta_data(factorAsArray[1], flows)
			var factorCon = _parse_delta_data(factorAsArray[2], flows)
			var factorProd = _parse_delta_data(factorAsArray[3], flows)
			var factorDesc = factorAsArray[4]
			var index = factorIndex + i - 1
			
			flows[index].cost = factorCost
			flows[index].consume = factorCon
			flows[index].produce = factorProd
			flows[index].desc = factorDesc
	
	var gameMaster = {"flows": flows, "factorIndex": factorIndex}
	return gameMaster

func _parse_card_data(flows: Array[Flow], factorIndex: int) -> Dictionary:
	var supplyCards: Array[supplyCard] = supplyCard.toSupplyCardArray(flows.slice(0, factorIndex))
	var factorCards: Array[factorCard] = factorCard.toFactorCardArray(flows.slice(factorIndex, flows.size()))
	var cardData = {"supplyCards": supplyCards, "factorCards": factorCards}
	return cardData

func _parse_supply_data(file: Array[String]) -> Array[Flow]:
	var supplies: Array[Flow]
	var supplyStringArray = file[0].split(",")
	for str in supplyStringArray:
		var flow: Flow
		var name: String
		var amount: int = 0
		if "." in str:
			name = str.split(".")[0].rstrip("\r")
			amount = int(str.split(".")[1])
		else:
			name = str.rstrip("\r")
		flow = Flow.new(name)
		flow.mod_quant(amount)
		supplies.append(flow)
	return supplies

func _parse_factor_data(file: Array[String], supplies: Array[Flow]) -> Array[Flow]:
	#NOTE: not used but retained for posterity
	var factors: Array[Flow]
	for i in range(1, file.size()):
		if !file[i].is_empty():
			var factorAsArray = file[i].split(";")
			var factorName = factorAsArray[0]
			var factorCost = _parse_delta_data(factorAsArray[1], supplies)
			var factorCon = _parse_delta_data(factorAsArray[2], supplies)
			var factorProd = _parse_delta_data(factorAsArray[3], supplies)
			var factorDesc = factorAsArray[4]
			
			var factor = Flow.new(factorName)
			factor.cost = factorCost
			factor.consume = factorCon
			factor.produce = factorProd
			factor.desc = factorDesc
			factors.append(factor)
	return factors

func _parse_delta_data(data: String, flows: Array[Flow]) -> Array[Delta]:
	var deltas: Array[Delta]
	var flowNames: Array[String]
	for flow in flows:
		flowNames.append(flow.name)
	var deltaDataAsArray = data.split(",")
	for datum in deltaDataAsArray:
		if !datum.is_empty():
			var delta: Delta
			var deltaParsed = datum.split(".")
			var deltaName = deltaParsed[0]
			if deltaName not in flowNames:
				print("ERROR: " + datum + " - Supply " + deltaName + " not in Supplies!")
			else:
				var index = flowNames.find(deltaName)
				var deltaAmt = deltaParsed[1]
				if deltaParsed[1].begins_with("R"):
					#parse as random
					delta = _parse_RNGdelta(flows[index], deltaAmt)
				else:
					#parse as constant
					deltaAmt = int(deltaParsed[1])
					delta = Delta.new(flows[index], deltaAmt)
				deltas.append(delta)
	return deltas

func _parse_RNGdelta(flow: Flow, RNG: String) -> Delta:
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
	delta = Delta.new(flow, 0, quant, val, offset)
	return delta

class factorCard extends PanelContainer:
	var flow: Flow
	var buyButton: Button
	var sellButton: Button
	var quantLabel: Label
	
	func _init(flow: Flow):
		self.flow = flow
		
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
		nameLabel.text = str(flow.name)
		var descLabel = Label.new()
		descLabel.text = str(flow.desc)
		var costLabel = Label.new()
		costLabel.text = flow.deltaAsString(flow.cost)
		self.buyButton = Button.new()
		buyButton.text = "Buy"
		self.quantLabel = Label.new()
		quantLabel.text = str(flow.quant)
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
		self.flow.buy(quant)
		self.quantLabel.text = str(self.flow.quant)
	
	func sell(quant: int):
		self.flow.sell(quant)
		self.quantLabel.text = str(self.flow.quant)
	
	func update():
		quantLabel.text = str(flow.quant)
	
	static func toFactorCardArray(factorArray: Array[Flow]) -> Array[factorCard]:
		var factorCardArray: Array[factorCard]
		for f in factorArray:
			var facCard = factorCard.new(f)
			factorCardArray.append(facCard)
		return factorCardArray

class supplyCard extends HBoxContainer:
	var flow: Flow
	var nameLabel: Label
	var quantLabel: Label
	
	func _init(flow: Flow):
		self.flow = flow
		self.nameLabel = Label.new()
		nameLabel.text = str(self.flow.name)
		self.quantLabel = Label.new()
		quantLabel.text = str(self.flow.quant)
		self.add_child(nameLabel)
		self.add_child(quantLabel)
	
	func update():
		quantLabel.text = str(flow.quant)
	
	static func toSupplyCardArray(supArray: Array[Flow]) -> Array[supplyCard]:
		var supCardArray: Array[supplyCard]
		for s in supArray:
			var supCard = supplyCard.new(s)
			supCardArray.append(supCard)
		return supCardArray

##Refactored IdleR API Java code to GDScript

# Delta class
class Delta:
	var flow: Flow
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
	func _init(flow: Flow, quant: int, diceQuant: int = 0, diceVal: int = 0, diceOffset: int = 0):
		self.flow = flow
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
			s = str(diceQuant) + "d" + str(diceVal) + sign + str(diceOffset) + " " + str(flow.name) + "s"
			
		else:
			s = str(quant) + " " + str(flow.name)
			if quant != 1:
				s = s + "s"
		return s

class Flow:
	var name: String = ""
	var desc: String = ""
	var quant: int = 0:
		set(value):
			if has_max and value > max:
				quant = max
			elif has_min and value < min:
				quant = min
			else:
				quant = value
	
	var max: int = 0:
		set(value):
			if has_min and value > min:
				has_max = true
				max = value
			else:
				print("%s's max cannot be lower than min" % name)
	var min: int = 0:
		set(value):
			if has_max and value < max:
				has_min = true
				min = value
			else:
				print("%s's min cannot be higher than max" % name)
	var cost: Array[Delta] = []:
		set(value):
			has_cost = true
			cost = value
	var produce: Array[Delta] = []:
		set(value):
			has_prod = true
			produce = value
	var consume: Array[Delta] = []:
		set(value):
			has_con = true
			consume = value
	var sell_factor: float = 0.5
	
	var has_max: bool = false
	var has_min: bool = true
	var has_cost: bool = false
	var has_prod: bool = false
	var has_con: bool = false
	
	var is_displayed: bool = true
	var is_sensitized: bool = true
	var can_buy: bool = true
	var can_sell: bool = true
	
	#Constructors
	func _init(name: String):
		self.name = name
		
	func newFactor(name: String):
		var flow = Flow.new(name)
		return flow
		
	func newSupply(name: String):
		var flow = Flow.new(name)
		return flow
	
	# Methods
	func mod_quant(amount: int):
		self.quant += amount
		
	func convert():
		for _i in range(quant):
			var can_afford = true
			if has_con:
				can_afford = false
				var go_count = 0
				for delta in consume:
					delta.rollQuant()
					if delta.flow.quant >= delta.quant:
						go_count += 1
				if go_count == consume.size():
					can_afford = true
					for delta in consume:
						delta.flow.mod_quant(-delta.quant)
			if can_afford and has_prod:
				for delta in produce:
					delta.rollQuant()
					delta.flow.mod_quant(delta.quant)

	func buy(amount: int):
		if amount > 0 and can_buy:
			var go_count = 0
			for cost_item in cost:
				if cost_item.flow.quant >= cost_item.quant * amount:
					go_count += 1
			if go_count == cost.size():
				for cost_item in cost:
					cost_item.flow.mod_quant(-cost_item.quant * amount)
				quant += amount

	func sell(amount: int):
		if amount <= quant and can_sell:
			for cost_item in cost:
				cost_item.flow.mod_quant(int(cost_item.quant * amount * sell_factor))
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
	var cost: Array[Delta] = []:
		set(value):
			has_cost = true
			cost = value
	var prod: Array[Delta] = []:
		set(value):
			has_prod = true
			prod = value
	var has_prod: bool = false
	var has_cost: bool = false
	var isDisplayed: bool = false
	var isSensitized: bool = false
	
	
	var doesChangeDelta = false
	var doesModQuant = false
	var doesUnlockElement = false

	# Constructor
	func _init(name: String, desc: String, cost: Array[Delta]=[], prod: Array[Delta]=[], isDisplayed: bool = false, isSensitized: bool = false):
		self.name = name
		self.desc = desc
		self.cost = cost
		self.prod = prod
		self.isDisplayed = isDisplayed
		self.isSensitized = isSensitized
