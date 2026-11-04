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
var _glow: Sprite2D = null
var _glow_base := 1.0
var _flick_phase := 0.0
var _flick_t := 0.0
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

## One shared radial-glow texture for every shot's burn halo, drawn
## once in code (white core fading out; the kind colour comes from the
## glow sprite's modulate).
static var _glow_tex: Texture2D = null

static func glow_texture() -> Texture2D:
    if _glow_tex != null:
        return _glow_tex
    var size = 128
    var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
    var centre = Vector2(size, size) * 0.5
    for y in size:
        for x in size:
            var d = Vector2(x, y).distance_to(centre) / (size * 0.5)
            var a = clamp(1.0 - d, 0.0, 1.0)
            img.set_pixel(x, y, Color(1, 1, 1, a * a))
    _glow_tex = ImageTexture.create_from_image(img)
    return _glow_tex

func _ready() -> void:
    gravity_scale = -1.45 # buoyant, brisker climb (speed pass 2026-11-04).
    linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
    linear_damp = 0.02 # low drag: higher top speed on the rise.
    _spr.texture = shot_texture(kind, id)
    var shape = CircleShape2D.new()
    shape.radius = RADII[id]
    _col.shape = shape
    _base_scale = _spr.scale
    # Burn halo: an additive glow sprite behind the orb, tinted by kind
    # (HOT red / COOL blue / WHITE white), flickering in _physics_process.
    _glow = Sprite2D.new()
    _glow.texture = glow_texture()
    _glow.show_behind_parent = true
    var mat = CanvasItemMaterial.new()
    mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
    _glow.material = mat
    var kind_cols = [Color(1.0, 0.5, 0.4), Color(0.45, 0.65, 1.0), Color(1.0, 0.98, 0.92)]
    _glow.modulate = kind_cols[kind]
    _glow_base = (RADII[id] * 2.0 * 2.55) / 128.0
    _glow.scale = Vector2.ONE * _glow_base
    add_child(_glow)
    _flick_phase = randf() * TAU

func _physics_process(delta: float) -> void:
    # Spawn-pop scale animation (the glow flares with the same pop).
    var pop := 1.0
    _spr.scale = _base_scale
    if _scale_timer > 0:
        _scale_timer -= delta
        var rate = _scale_timer / TIMER_SCALE
        pop = 1 + 0.1 * Ease.back_out(1 - rate)
        _spr.scale *= Vector2(pop, pop)
    # Burn flicker: two detuned sines per shot (random phase) so no two
    # shots pulse together - the halo breathes and the core shimmers.
    _flick_t += delta
    var fl = sin(_flick_t * 11.0 + _flick_phase) * 0.6 + sin(_flick_t * 23.7 + _flick_phase * 1.7) * 0.4
    if _glow != null:
        _glow.scale = Vector2.ONE * _glow_base * pop * (1.0 + 0.07 * fl)
        var ga = 0.66 + 0.17 * fl + 0.02 * id # bigger shots burn a touch stronger.
        _glow.modulate.a = clamp(ga, 0.25, 0.9)
    # Red flash while over the line.
    var bright = 1.0 + 0.05 * fl
    _spr.modulate = Color(bright, bright, bright)
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
