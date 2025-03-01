extends CanvasLayer

const IdleR = preload("res://IdleR.gd")
var idleR = IdleR.new()

@onready var factor_grid_container: GridContainer = $FactorGridContainer
@onready var grid_container: GridContainer = $SupplyPanelContainer/MarginContainer/GridContainer

#File handling

var fileName = "game.txt"
var file = FileAccess.open(fileName, FileAccess.READ)
var fileAsArray = file.get_file_as_string(fileName).split("\n")

var supplies = idleR._parse_supply_data(fileAsArray)
var factors = idleR._parse_factor_data(fileAsArray, supplies)
var supplyCards: Array[IdleR.supplyCard] = idleR.supplyCard.toSupplyCardArray(supplies)
	

func _ready():
	##Build GUI
	#Add Supply Cards
	for card in supplyCards:
		grid_container.add_child(card)
	
	#Add Factor Cards
	for f in factors:
		var fCard = idleR.factorCard.new(f)
		#Bind buy & sell buttons
		fCard.buyButton.pressed.connect(fCard.buy.bind(1))
		fCard.buyButton.pressed.connect(_update_supplies.bind())
		fCard.sellButton.pressed.connect(fCard.sell.bind(1))
		fCard.sellButton.pressed.connect(_update_supplies.bind())
		factor_grid_container.add_child(fCard)
		
		#var buy10button = Button.new()
		#buy10button.pressed.connect(fCard.buy.bind(10))
		#buy10button.pressed.connect(_update_supplies.bind())
		#buy10button.text = "Buy 10"
		#factor_grid_container.add_child(buy10button)

func _on_button_pressed() -> void:
	# +1 Dollar
	supplies[0].mod_quant(1)
	_update_supplies()

func _on_button_2_pressed() -> void:
	# +1 Wood, -2 Dollar
	if supplies[0].quant >= 2:
		supplies[0].mod_quant(-2)
		supplies[1].mod_quant(1)
		_update_supplies()
	

func _process(delta: float) -> void:
	_update_supplies()

func _on_timer_timeout() -> void:
	for f in factors:
		f.convert()
	_update_supplies()

func _update_supplies() -> void:
	for card in supplyCards:
		card.update()
