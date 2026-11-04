extends Node2D
# Shooting Stars - main scene.
# INVERTED Suika: the launcher sits at the BOTTOM, shots float UP and
# pile against the ceiling; the game ends when the pile sinks back down
# past the red line near the launcher.
# Adapted from gd_suikagame's Main.gd (MIT, (c) 2023 syun).

## Height of the launcher (held shot) - near the bottom of the box.
const DROP_POS_Y = 545.0
## Spawn pool: shot ids 0..3 (levels 1-4), weighted to small shots.
const SPAWN_IDS = [0, 0, 0, 0, 1, 1, 1, 2, 2, 3, 3, 4]
## Evolution column nodes in Main.tscn, index = shot id.
const EVO_NODES = ["Bullet", "Carrot", "Radish", "Pocky", "Banana", "Nasu", "Tako", "Nya", "5Box", "Milk", "Pudding"]

enum eState { INIT, MAIN, DROP_WAIT, GAME_OVER }

@onready var _deadline = $DeadLine
@onready var _marker_left = $Marker/Left
@onready var _marker_right = $Marker/Right
@onready var _spr_line = $Line
@onready var _wall_layer = $WallLayer
@onready var _fruit_layer = $ShotLayer
@onready var _particle_layer = $ParticleLayer
@onready var _ui_layer = $UILayer
@onready var _ui_now = $UILayer/NowShot
@onready var _ui_dbg_label = $UILayer/DbgLabel
@onready var _ui_evolution_label = $UILayer/Evolution/Label
@onready var _ui_caption = $UILayer/Caption
@onready var _ui_gauge = $UILayer/ProgressBar
@onready var _ui_next = $UILayer/Next/Sprite2D
@onready var _ui_score = $UILayer/Score
@onready var _ui_score_sub = $UILayer/Score/SubLabel
@onready var _ui_hi_score = $UILayer/HiScore
@onready var _bgm = $Bgm

var _state = eState.INIT
var _now_id = 0
var _now_kind = 0
var _next_id = 0
var _next_kind = 0
var _fruit: Shot = null
var _bgm_id = 0
var _evolution_sprs = {}
var _evolution_scales = {}

func _ready() -> void:
    var layers = {
        "wall": _wall_layer,
        "shot": _fruit_layer,
        "particle": _particle_layer,
        "ui": _ui_layer,
    }
    Common.setup(layers)
    _setup_evolution()
    _ui_dbg_label.visible = true
    _ui_dbg_label.position = Vector2(40, 262) # clear of the SCORE block.
    var cap_first = true
    for child in _ui_caption.get_children():
        if child is Label:
            child.text = "OVERRUN" if cap_first else "press R to play again"
            cap_first = false
    _bgm.play()

## The right-hand column shows one WHITE shot per level (the neutral
## form of each); the base project's 12th slot is hidden (11 levels).
func _setup_evolution() -> void:
    for i in EVO_NODES.size():
        var spr = get_node("UILayer/Evolution/" + EVO_NODES[i])
        spr.texture = Shot.shot_texture(Shot.Kind.WHITE, i)
        spr.scale = Vector2.ONE * (44.0 / spr.texture.get_width())
        _evolution_sprs[i] = spr
        _evolution_scales[i] = spr.scale
    $UILayer/Evolution/Xbox.visible = false

func _pick_kind() -> int:
    var r = randf()
    if r < 0.4:
        return Shot.Kind.HOT
    if r < 0.8:
        return Shot.Kind.COOL
    return Shot.Kind.WHITE

func _lot_shot() -> void:
    _now_id = _next_id
    _now_kind = _next_kind
    _next_id = SPAWN_IDS[randi() % SPAWN_IDS.size()]
    _next_kind = _pick_kind()
    _ui_next.texture = Shot.shot_texture(_next_kind, _next_id)
    _ui_next.scale = Vector2.ONE * (52.0 / _ui_next.texture.get_width())
    _ui_now.texture = Shot.shot_texture(_now_kind, _now_id)
    _ui_now.scale = Vector2.ONE
    _ui_now.modulate.a = 0.55

func _process(delta: float) -> void:
    match _state:
        eState.INIT:
            _update_init()
        eState.MAIN:
            _update_main(delta)
        eState.DROP_WAIT:
            _update_drop_wait(delta)
        eState.GAME_OVER:
            _update_game_over()
    _update_ui(delta)
    _update_debug()

func _update_init() -> void:
    _lot_shot()
    _state = eState.MAIN

func _update_main(delta: float) -> void:
    _update_dead_line_gauge()
    if _is_gameover(delta):
        _start_gameover()
        _state = eState.GAME_OVER
        return
    _update_cursor()
    if Input.is_action_just_pressed("click"):
        Common.play_se("drop", 1)
        _ui_now.visible = false
        _spr_line.visible = false
        var shot = Common.create_shot(_now_id, _now_kind, false, Vector2.ZERO, 0, true)
        shot.position = _ui_now.position
        _fruit = shot
        _state = eState.DROP_WAIT

func _update_drop_wait(delta: float) -> void:
    _update_dead_line_gauge()
    if _is_gameover(delta):
        _start_gameover()
        _state = eState.GAME_OVER
        return
    if _is_dropped(_fruit) == false:
        return
    _fruit = null
    _lot_shot()
    _state = eState.MAIN

func _update_game_over() -> void:
    pass

func _update_cursor() -> void:
    var px = get_global_mouse_position().x
    px = clamp(px, _marker_left.position.x, _marker_right.position.x)
    _ui_now.visible = true
    _ui_now.position = Vector2(px, DROP_POS_Y)
    _spr_line.visible = true
    _spr_line.position = Vector2(px, 300)
    _spr_line.modulate.a = 0.5

func _is_dropped(node) -> bool:
    if is_instance_valid(node) == false:
        return true
    var shot = node as Shot
    return shot.is_hit_even_once()

func _is_gameover(delta: float) -> bool:
    for obj in _fruit_layer.get_children():
        var shot = obj as Shot
        if shot.check_gameover(_deadline.position.y, delta):
            return true
    return false

func _start_gameover() -> void:
    PhysicsServer2D.set_active(false)
    for obj in _fruit_layer.get_children():
        obj.set_physics_process(false)
    _ui_caption.visible = true
    _spr_line.visible = false
    _ui_now.visible = false

func _update_ui(delta: float) -> void:
    _ui_score.text = "SCORE: %d" % Common.score
    _ui_hi_score.text = "HI-SCORE: %d" % Common.hi_score
    if _count_score_particle() == 0:
        Common.disp_add_score = 0
        _ui_score_sub.visible = false
    if Common.disp_add_score > 0:
        _ui_score_sub.visible = true
        _ui_score_sub.text = "(+%d)" % Common.disp_add_score
    # Balance readout: HOT (red, Left) vs COOL (blue, Right).
    var bal = Common.hot_pts - Common.cool_pts
    var bal_txt = ("+" if bal > 0 else "") + str(bal)
    _ui_dbg_label.text = "HOT %d    COOL %d    BALANCE %s" % [Common.hot_pts, Common.cool_pts, bal_txt]
    # Evolution column pulse when a new shot of that level appears.
    Common.update_shot_timer(delta)
    for i in _evolution_sprs.keys():
        var t = Common.get_shot_timer(i)
        var sc = _evolution_scales[i]
        if t > 0:
            var rate = 1 + Ease.elastic_out(1 - t)
            sc *= (Vector2.ONE * rate)
        _evolution_sprs[i].scale = sc
    # Count shots per level; BGM rises with the biggest shot.
    var tbl = {}
    var max_id = 0
    for obj in _fruit_layer.get_children():
        var shot = obj as Shot
        tbl[shot.id] = tbl.get(shot.id, 0) + 1
        if max_id < shot.id:
            max_id = shot.id
    if max_id >= 10:
        if _bgm_id < 4:
            _bgm.stream = load("res://assets/sound/bgm/bgm05_140.mp3")
            _bgm.play()
            _bgm_id = 5
    elif max_id >= 8:
        if _bgm_id < 3:
            _bgm.stream = load("res://assets/sound/bgm/bgm04_110.mp3")
            _bgm.play()
            _bgm_id = 3
    elif max_id >= 6:
        if _bgm_id < 2:
            _bgm.stream = load("res://assets/sound/bgm/bgm03_140.mp3")
            _bgm.play()
            _bgm_id = 2
    elif max_id >= 4:
        if _bgm_id < 1:
            _bgm.stream = load("res://assets/sound/bgm/bgm02_140.mp3")
            _bgm.play()
            _bgm_id = 1
    _ui_evolution_label.text = ""
    var ids = range(10, -1, -1)
    for i in ids:
        if i in tbl:
            _ui_evolution_label.text += "SHOT %d: %d\n" % [i + 1, tbl[i]]
        else:
            _ui_evolution_label.text += "\n"

func _update_dead_line_gauge() -> void:
    var max_rate = 0.0
    var max_obj: Shot = null
    for obj in _fruit_layer.get_children():
        var shot = obj as Shot
        var rate = shot.get_gameover_timer_rate()
        if rate > max_rate:
            max_rate = rate
            max_obj = shot
    if max_obj:
        var pitch = 1 - (0.5 * max_rate)
        pitch = max(0.75, pitch)
        _bgm.pitch_scale = pitch
        AudioServer.set_bus_effect_enabled(1, 0, true)
        _ui_gauge.visible = true
        _ui_gauge.value = 100 * max_rate
        _ui_gauge.position = max_obj.position
    else:
        _ui_gauge.visible = false
        AudioServer.set_bus_effect_enabled(1, 0, false)
        _bgm.pitch_scale = 1.0

func _count_score_particle() -> int:
    var ret = 0
    for obj in _particle_layer.get_children():
        if obj is ParticleScore:
            ret += 1
    return ret

func _update_debug() -> void:
    if Input.is_action_just_pressed("reset"):
        PhysicsServer2D.set_active(true)
        get_tree().change_scene_to_file("res://Main.tscn")
