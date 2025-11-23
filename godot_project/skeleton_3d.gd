extends Skeleton3D

@onready var effector_L = $GodotIK/EffectorFL
@onready var effector_R = $GodotIK/EffectorFR
@onready var ball = %Ball

var base_pos_L: Vector3
var base_pos_R: Vector3

var walk_timer := 0.0
var step_speed := 5.0
var step_distance := 0.2
var step_height := 0.15

var is_walking := false
var kick_timer_L := 0.0
var kick_timer_R := 0.0
var kick_height_L := 0.1
var kick_height_R := 0.1
var kick_power_L := 1.0
var kick_power_R := 1.0

# Ngưỡng kiểm tra khoảng cách để được xem là "gần chân"
const BALL_KICK_DISTANCE = 10
var original_pos_L: Vector3
var original_pos_R: Vector3

func _ready():
	prints(effector_L,effector_R)
	base_pos_L = effector_L.position
	base_pos_R = effector_R.position
	original_pos_L = effector_L.global_position
	original_pos_R = effector_R.global_position

func _process(delta):
	if is_walking:
		walk_cycle(delta)
	
	# Nếu đang sút chân trái
	if kick_timer_L > 0:
		kick_timer_L -= delta
		animate_kick_leg("left", kick_timer_L, kick_height_L, kick_power_L)

	if kick_timer_R > 0:
		kick_timer_R -= delta
		animate_kick_leg("right", kick_timer_R, kick_height_R, kick_power_R)

# === 🦶 Procedural walk ===
func walk_cycle(delta):
	walk_timer += delta * step_speed

	var phase_L = sin(walk_timer)
	var phase_R = sin(walk_timer + PI)

	var offset_L = Vector3(0, abs(phase_L) * step_height, phase_L * step_distance)
	var offset_R = Vector3(0, abs(phase_R) * step_height, phase_R * step_distance)

	effector_L.position = base_pos_L + offset_L
	effector_R.position = base_pos_R + offset_R

# === Gọi sút chân với lực và độ cao ===
func kick_leg(leg: String, power: float = 1.0, height: float = 0.1):
	var duration = 0.4 / power
	if leg == "left":
		kick_timer_L = duration
		kick_height_L = height
		kick_power_L = power
	elif leg == "right":
		kick_timer_R = duration
		kick_height_R = height
		kick_power_R = power

# === Animate kick chân trái/phải ===
func animate_kick_leg(leg: String, time_left: float, height: float, power: float):
	var kick_phase = sin((1.0 - time_left * power / 0.4) * PI)
	var kick_offset = Vector3(0, kick_phase * height, kick_phase * 0.4)

	if leg == "left":
		effector_L.position = base_pos_L + kick_offset
	elif leg == "right":
		effector_R.position = base_pos_R + kick_offset

func kick_ball_old(leg: String):
	var effector = effector_L if leg == "left" else effector_R
	var original_pos = original_pos_L if leg == "left" else original_pos_R
	var foot_pos = effector.global_position
	var ball_pos = ball.global_position

	# Nếu bóng quá xa thì bỏ qua
	if foot_pos.distance_to(ball_pos) > 1.0:
		return

	# Đưa chân về phía bóng
	var kick_pos = foot_pos.lerp(ball_pos, 0.8)
	kick_pos.y += 0.2 # nâng nhẹ chân lên

	effector.global_position = kick_pos

	# Thu chân về sau 0.3 giây
	#await get_tree().create_timer(0.3).timeout
	#effector.global_position = original_pos
	await get_tree().create_timer(0.2).timeout
	var tween := create_tween()
	tween.tween_property(effector, "global_position", original_pos, 0.3)

func kick_ball(leg: String, power: float = 1.0, pull_back: float = 0.2):
	var effector: Node3D = effector_L if leg == "left" else effector_R
	var foot_pos: Vector3 = effector.global_position
	var ball_pos: Vector3 = ball.global_position
	
	var dir: Vector3 = (ball_pos - foot_pos).normalized()
	var distance: float = foot_pos.distance_to(ball_pos)
	
	if distance > 2.0:
		return
	
	var back_pos: Vector3 = foot_pos - dir * pull_back + Vector3.UP * 0.2
	var kick_pos: Vector3 = ball_pos + dir * power + Vector3.UP * 0.05

	# Tạo tween
	var tween := create_tween()
	tween.tween_property(effector, "global_position", back_pos, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(effector, "global_position", kick_pos, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(effector, "global_position", foot_pos, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	await tween.finished

func _input(event):
	if Input.is_action_just_pressed("ui_up"):
		is_walking = true
	if Input.is_action_just_pressed("ui_left"):
		#kick_leg("left",2.0, 0.3)
		kick_ball("left")
	elif Input.is_action_just_pressed("ui_right"):
		#kick_leg("right", 1.0, 0.1)
		kick_ball("right")
