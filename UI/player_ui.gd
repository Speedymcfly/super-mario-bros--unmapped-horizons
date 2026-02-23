extends CanvasLayer

@onready var coin_counter: AnimatedSprite2D = $Control/CoinCounter
@onready var common_coin_counter: Label = $Control/CommonCoinCounter
@onready var lumina_coin_counter: Label = $Control/LuminaCoinCounter
@onready var life_character: AnimatedSprite2D = $Control/LifeCharacter
@onready var life_counter: Label = $Control/LifeCounter






func _ready() -> void:
	update_hud()


func update_hud() -> void:

	var plr = get_tree().get_first_node_in_group("player")

	common_coin_counter.text = "x" + str(Globals.coin_amount).pad_zeros(3)
	lumina_coin_counter.text = "x" + str(Globals.lumina_coin_amount).pad_zeros(3)
	if plr.character == plr.Character.Mario:
		life_counter.text = "x" + str(Globals.mario_lives).pad_zeros(2)
		life_character.animation = "Mario"
	if plr.character == plr.Character.Luigi:
		life_counter.text = "x" + str(Globals.luigi_lives).pad_zeros(2)
		life_character.animation = "Luigi"
	if plr.character == plr.Character.Toad:
		life_counter.text = "x" + str(Globals.toad_lives).pad_zeros(2)
		life_character.animation = "Toad"
	if plr.character == plr.Character.Toadette:
		life_counter.text = "x" + str(Globals.toadette_lives).pad_zeros(2)
		life_character.animation = "Toadette"
	if plr.character == plr.Character.Peach:
		life_counter.text = "x" + str(Globals.peach_lives).pad_zeros(2)
		life_character.animation = "Peach"
	if plr.character == plr.Character.Daisy:
		life_counter.text = "x" + str(Globals.daisy_lives).pad_zeros(2)
		life_character.animation = "Daisy"
