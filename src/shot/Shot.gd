extends RigidBody2D
# Shooting Stars piece: a buoyant shot orb.
# Adapted from gd_suikagame's Shot.gd (MIT, (c) 2023 syun) - see
# LICENSE-MIT-base.txt. One generic scene now serves every shot; the
# level and kind are data, set before the node enters the tree.
class_name Shot

## Star kinds. HOT burns blue (real hot shots are blue), COOL glows red
## (real cool shots are red), WHITE is the balanced sun-like shot.
enum Kind { HOT, COOL, WHITE }

const MAX_ID = 10 # levels 1..11 -> ids 0..10
const RADII = [19, 25, 31, 38, 45, 53, 61, 71, 80, 91, 102]
const KIND_NAMES = ["hot", "cool", "white"]
const TIMER_HIT = 0.5 # flash time after crossing the line.
const TIMER_SCALE = 0.3 # spawn pop time.
const TIMER_GAMEOVER = 3.0 * 2 # grace seconds (timer runs at 2x).

@export var id: int = 0
@export var kind: int = 0 # Kind.HOT

@onready var _spr = $Sprite
@onready var _col = $CollisionShape2D

var _base_scale: Vector2 = Vector2.ONE
var _gameover_timer = 0.0
var _hit_count = 0
var _scale_timer = 0.0

static func shot_texture(p_kind: int, p_id: int) -> Texture2D:
    return load("res://assets/images/shots/%s_%d.png" % [KIND_NAMES[p_kind], p_id])

static func radius_of(p_id: int) -> int:
    return RADII[p_id]

func get_sprite_scale() -> Vector2:
    return _spr.scale

func is_hit_even_once() -> bool:
    return _hit_count > 0

func start_scale() -> void:
    _scale_timer = TIMER_SCALE

## Inverted game-over: a settled shot SINKING below the line (toward the
## launcher at the bottom) is what ends the game.
func check_gameover(y: float, delta: float) -> bool:
    if is_hit_even_once() == false:
        return false # still in flight: not counted.
    if position.y > y and linear_velocity.length() < 40:
        # Only a SETTLED shot counts - one still bouncing along the
        # floor after launch must not end the game.
        _gameover_timer += (delta * 2)
        if _gameover_timer > TIMER_GAMEOVER:
            return true
    return false

func get_gameover_timer_rate() -> float:
    return _gameover_timer / TIMER_GAMEOVER

func _ready() -> void:
    gravity_scale = -1.0 # buoyant: shots float UP.
    _spr.texture = shot_texture(kind, id)
    var shape = CircleShape2D.new()
    shape.radius = RADII[id]
    _col.shape = shape
    _base_scale = _spr.scale

func _physics_process(delta: float) -> void:
    # Spawn-pop scale animation.
    _spr.scale = _base_scale
    if _scale_timer > 0:
        _scale_timer -= delta
        var rate = _scale_timer / TIMER_SCALE
        rate = 1 + 0.1 * Ease.back_out(1 - rate)
        _spr.scale *= Vector2(rate, rate)
    # Red flash while over the line.
    _spr.modulate = Color.WHITE
    if _gameover_timer > 0:
        var rate = 1 - (_gameover_timer / TIMER_HIT)
        _gameover_timer -= delta
        _spr.modulate = Color.RED.lerp(Color.WHITE, rate)

## Merge table (George's rules):
##  same kind      -> next level, same kind; points go to that side
##                    (WHITE+WHITE: next WHITE, total points only)
##  HOT + COOL     -> next level WHITE, total only
##  WHITE + a side -> next level of that side's kind, total only
##  11 + 11        -> both clear, +22 total (handled by the caller)
## Returns [result_id, result_kind, score_mode]; score_mode:
## 0 = total only, 1 = HOT side, 2 = COOL side.
func _merge_result(other: Shot) -> Array:
    if kind == other.kind:
        if kind == Kind.WHITE:
            return [id + 1, Kind.WHITE, 0]
        return [id + 1, kind, 1 if kind == Kind.HOT else 2]
    if kind != Kind.WHITE and other.kind != Kind.WHITE:
        return [id + 1, Kind.WHITE, 0]
    var side = other.kind if kind == Kind.WHITE else kind
    return [id + 1, side, 0]

func _on_body_entered(body: Node) -> void:
    _hit_count += 1
    if not body is Shot:
        return
    if self.is_queued_for_deletion() or body.is_queued_for_deletion():
        return
    var other = body as Shot
    if id != other.id:
        return
    var pos = (position + other.position) / 2
    if id >= MAX_ID:
        # Two 11s clear each other.
        Common.add_clear_score(pos)
        queue_free()
        other.queue_free()
        return
    var res = _merge_result(other)
    var shot = Common.create_shot(res[0], res[1], true, pos, res[2])
    shot.position = pos
    shot.start_scale()
    queue_free()
    other.queue_free()
