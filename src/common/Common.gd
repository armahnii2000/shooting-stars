extends Node
# Shared state and services (autoload).
# Adapted from gd_suikagame's Common.gd (MIT, (c) 2023 syun).

const MAX_SOUND = 8
const TIMER_SHOT_APPEAR = 1.0

var _snd_tbl = {
    "drop": "res://assets/sound/se/drop.wav",
    "merge": "res://assets/sound/se/merge.wav",
}

const SHOT_SCENE = preload("res://src/shot/Shot.tscn")

var _snds: Array = []
var _layers = {}
var _shot_timers = {}

var score: int = 0 # total points (the HUD score).
var hi_score: int = 0
var hot_pts: int = 0 # Left side: blue HOT shots.
var cool_pts: int = 0 # Right side: red COOL shots.
var disp_add_score: int = 0

func setup(layers) -> void:
    score = 0
    hot_pts = 0
    cool_pts = 0
    disp_add_score = 0
    _shot_timers.clear()
    _layers = layers
    for i in range(MAX_SOUND):
        var snd = AudioStreamPlayer.new()
        snd.bus = "SE"
        add_child(snd)
        _snds.append(snd)

func get_layer(layer_name: String) -> CanvasLayer:
    return _layers[layer_name]

## Points for a merge = the NEW shot's level (George's draft table).
## score_mode: 0 = total only, 1 = HOT side, 2 = COOL side.
func _award(points: int, score_mode: int, pos: Vector2) -> void:
    score += points
    if score_mode == 1:
        hot_pts += points
    elif score_mode == 2:
        cool_pts += points
    if score > hi_score:
        hi_score = score
    disp_add_score += points
    ParticleUtil.add_score(pos, points)

## Two 11s clearing each other pay 22, total only.
func add_clear_score(pos: Vector2) -> void:
    _award(22, 0, pos)
    play_se("merge", 2)

func create_shot(p_id: int, p_kind: int, is_deferred: bool = false, particle_pos: Vector2 = Vector2.ZERO, score_mode: int = 0, launch: bool = false) -> Shot:
    var shot = SHOT_SCENE.instantiate()
    shot.id = p_id
    shot.kind = p_kind
    var layer = get_layer("shot")
    if is_deferred:
        # Called from a physics signal: adding a child must be deferred.
        layer.call_deferred("add_child", shot)
        _shot_timers[p_id] = TIMER_SHOT_APPEAR
        _award(p_id + 1, score_mode, particle_pos)
        play_se("merge", 2)
    else:
        layer.add_child(shot)
        if launch:
            shot.linear_velocity = Vector2(0, -160)
    return shot

func update_shot_timer(delta: float) -> void:
    for k in _shot_timers.keys():
        if _shot_timers[k] > 0:
            _shot_timers[k] -= delta

func get_shot_timer(p_id: int) -> float:
    return max(_shot_timers.get(p_id, 0.0), 0.0)

func play_se(key: String, p_id: int = 0) -> void:
    if p_id < 0 or MAX_SOUND <= p_id:
        push_error("bad sound id %d" % p_id)
        return
    if not key in _snd_tbl:
        push_error("unknown sound %s" % key)
        return
    var snd = _snds[p_id]
    snd.stream = load(_snd_tbl[key])
    snd.play()
