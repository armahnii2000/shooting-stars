extends SceneTree

var inst
var C
var drops = 0
var merges = 0
var last_score = 0
var max_id = 0
var shot_taken = false

func _initialize() -> void:
    Engine.time_scale = 2.0
    inst = load("res://Main.tscn").instantiate()
    root.add_child(inst)
    C = root.get_node("Common")
    _run()

func _stars() -> Array:
    return C.call("get_layer", "shot").get_children()

func _choose_x() -> float:
    var nid = inst.get("_now_id")
    var nkind = inst.get("_now_kind")
    var best = -1.0
    var best_y = -1.0e9
    for s in _stars():
        if s.id == nid and s.kind == nkind and s.position.y > best_y:
            best_y = s.position.y
            best = s.position.x
    if best < 0:
        best = 576 + randf_range(-130, 130)
    return clamp(best, 428, 724)

func _run() -> void:
    for i in 40:
        await process_frame
    while drops < 250:
        if inst.get("_state") == 3:
            break
        var x = _choose_x()
        root.warp_mouse(Vector2(x, 300))
        for i in 8:
            await process_frame
        Input.action_press("click")
        await process_frame
        Input.action_release("click")
        drops += 1
        var wait = 0
        while wait < 900:
            await process_frame
            if C.get("score") != last_score:
                merges += 1
                last_score = C.get("score")
            if inst.get("_state") == 1 or inst.get("_state") == 3:
                break
            wait += 1
        for s in _stars():
            if s.id > max_id:
                max_id = s.id
        if drops == 40 and not shot_taken:
            shot_taken = true
            root.get_texture().get_image().save_png("/home/hatch/workspace/.verify-tilt/ss-bot-mid.png")
    root.get_texture().get_image().save_png("/home/hatch/workspace/.verify-tilt/ss-bot-end.png")
    print("RESULT drops=", drops, " merges=", merges, " score=", C.get("score"), " hot=", C.get("hot_pts"), " cool=", C.get("cool_pts"), " max_level=", max_id + 1, " stars_left=", _stars().size(), " state=", inst.get("_state"))
    quit()
