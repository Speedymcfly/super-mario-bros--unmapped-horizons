extends CanvasLayer

@onready var coin_counter: AnimatedSprite2D = $Control/CoinCounter
@onready var common_coin_counter: Label = $Control/CommonCoinCounter
@onready var lumina_coin_counter: Label = $Control/LuminaCoinCounter
@onready var life_character: AnimatedSprite2D = $Control/LifeCharacter
@onready var life_counter: Label = $Control/LifeCounter
@onready var super_diamond_counter: Label = $Control/SuperDiamondCounter
@onready var power_meter_arrow_1: AnimatedSprite2D = $Control/PowerMeterArrow1
@onready var power_meter_arrow_2: AnimatedSprite2D = $Control/PowerMeterArrow2
@onready var power_meter_arrow_3: AnimatedSprite2D = $Control/PowerMeterArrow3
@onready var power_meter_arrow_4: AnimatedSprite2D = $Control/PowerMeterArrow4
@onready var power_meter_arrow_5: AnimatedSprite2D = $Control/PowerMeterArrow5
@onready var power_meter_arrow_6: AnimatedSprite2D = $Control/PowerMeterArrow6
@onready var power_meter_icon: AnimatedSprite2D = $Control/PowerMeterIcon





func _ready() -> void:
	update_hud()

func update_hud() -> void:

	var plr = get_tree().get_first_node_in_group("player")

	common_coin_counter.text = "x" + str(Globals.coin_amount).pad_zeros(3)
	lumina_coin_counter.text = "x" + str(Globals.lumina_coin_amount).pad_zeros(3)
	super_diamond_counter.text = "x" + str(Globals.super_diamond_amount).pad_zeros(2)
	if plr.character == plr.Character.Mario and Globals.shared_lives == false:
		life_counter.text = "x" + str(Globals.mario_lives).pad_zeros(2)
		life_character.animation = "Mario"
	if plr.character == plr.Character.Luigi and Globals.shared_lives == false:
		life_counter.text = "x" + str(Globals.luigi_lives).pad_zeros(2)
		life_character.animation = "Luigi"
	if plr.character == plr.Character.Toad and Globals.shared_lives == false:
		life_counter.text = "x" + str(Globals.toad_lives).pad_zeros(2)
		life_character.animation = "Toad"
	if plr.character == plr.Character.Toadette and Globals.shared_lives == false:
		life_counter.text = "x" + str(Globals.toadette_lives).pad_zeros(2)
		life_character.animation = "Toadette"
	if plr.character == plr.Character.Peach and Globals.shared_lives == false:
		life_counter.text = "x" + str(Globals.peach_lives).pad_zeros(2)
		life_character.animation = "Peach"
	if plr.character == plr.Character.Daisy and Globals.shared_lives == false:
		life_counter.text = "x" + str(Globals.daisy_lives).pad_zeros(2)
		life_character.animation = "Daisy"
	if Globals.shared_lives == true:
		life_counter.text = "x" + str(Globals.lives).pad_zeros(2)
		if plr.character == plr.Character.Mario:
			life_character.animation = "Mario"
		if plr.character == plr.Character.Luigi:
			life_character.animation = "Luigi"
		if plr.character == plr.Character.Toad:
			life_character.animation = "Toad"
		if plr.character == plr.Character.Toadette:
			life_character.animation = "Toadette"
		if plr.character == plr.Character.Peach:
			life_character.animation = "Peach"
		if plr.character == plr.Character.Daisy:
			life_character.animation = "Daisy"
	if plr.power_full == true:
		power_meter_arrow_1.play("active")
		power_meter_arrow_2.play("active")
		power_meter_arrow_3.play("active")
		power_meter_arrow_4.play("active")
		power_meter_arrow_5.play("active")
		power_meter_arrow_6.play("active")
		power_meter_icon.play("active")
