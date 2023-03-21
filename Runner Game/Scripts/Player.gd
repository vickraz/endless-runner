extends KinematicBody2D
class_name Player

signal dead(distance)

onready var anim = $AnimationPlayer
onready var coyoteTimer = $CoyoteTimer
onready var upSlopeRay = $UpSlopeRay
onready var downSlopeRay = $DownSlopeRay
onready var distanceText = $HUD/DistanceText
onready var runningParticles = $RunningParticles

const ACC = 300
const NORM_GRAVITY = 1200
const MIN_GRAVITY = 400
const MAX_GRAVITY = 3200
const JUMP_STRENGHT = -590
const MAX_HOLD_TIME = 0.4;
const follow_slope_const = -PI/4

var gravity := NORM_GRAVITY
var max_speed = 320
var prevoius_y_vel = 0
var can_jump = true
var want_to_jump := false
var holding_jump := false
var hold_time := 0.0
var jumpbuffer := 0.0

var input_vector := Vector2.ZERO
var velocity := Vector2.ZERO
var distance_traveled := 0.0

enum {IDLE, RUNNING, AIR, SLIDE, DEAD}

var state = RUNNING

onready var start_x = global_position.x

var impact_scene = preload("res://Scenes/ImpactSmoke.tscn")

func _physics_process(delta: float) -> void:
	match state:
		IDLE:
			_enter_run_state()
		RUNNING: 
			_run_state(delta)
		AIR:
			_air_state(delta)
		SLIDE:
			pass
		DEAD:
			pass
	distance_traveled = (global_position.x - start_x) / 20.0
	distanceText.text = "Distance: " + str(round(distance_traveled)) + " m"
	if global_position.y > 620:
		emit_signal("dead", round(distance_traveled))
		state = DEAD
		visible = false
		distanceText.visible = false

#general help functions
func _move_player(delta) -> void:
	prevoius_y_vel = velocity.y
	if _on_up_slope():
		velocity = velocity.move_toward(Vector2.RIGHT.rotated(follow_slope_const) * max_speed
										, 800 * delta)
	else:
		velocity.x = move_toward(velocity.x, max_speed, ACC*delta)
		velocity.y += gravity * delta
		
	velocity.y = clamp(velocity.y, -800, 800)
	if _on_down_slope():
		velocity = move_and_slide_with_snap(velocity, Vector2.DOWN * 5,Vector2.UP,
										false, 5, deg2rad(50), true)
	else:
		velocity = move_and_slide_with_snap(velocity, Vector2.DOWN * 5,Vector2.UP,
										true, 5, deg2rad(50), true)
	
	if is_on_wall():
		velocity.x = 0

func _on_up_slope() -> bool:
	upSlopeRay.force_raycast_update()
	if upSlopeRay.is_colliding():
		var norm = upSlopeRay.get_collision_normal()
		if not norm.is_equal_approx(Vector2(-1,0)):
			return true
	return false

func _on_down_slope() -> bool:
	downSlopeRay.force_raycast_update()
	return downSlopeRay.is_colliding()

#state-functions
func _idle_state(delta: float) -> void:
	pass

func _run_state(delta: float) -> void:
	if Input.is_action_just_pressed("jump") and can_jump:
		_enter_air_state(true)
		
	_move_player(delta)
	
	if not is_on_floor():
		_enter_air_state(false)

func _air_state(delta: float) -> void:
	if Input.is_action_just_released("jump"):
		holding_jump = false
	
	if Input.is_action_just_pressed("jump") and can_jump:
		_enter_air_state(true)
	elif Input.is_action_just_pressed("jump"):
		want_to_jump = true
		
	if Input.is_action_pressed("ui_down"):
		gravity = MAX_GRAVITY
		holding_jump = false
		hold_time = 0.0
	elif not holding_jump:
		gravity = NORM_GRAVITY
	else:
		gravity = MIN_GRAVITY
		hold_time += delta
		if hold_time >= MAX_HOLD_TIME:
			holding_jump = false
			hold_time = 0.0
			
			
	_move_player(delta)
	
	if want_to_jump:
		jumpbuffer += delta
	
	
	if velocity.y > 0:
		anim.play("Fall")
	
	if is_on_floor():
		if want_to_jump and jumpbuffer < 0.1:
			_enter_air_state(true)
		else:
			_enter_run_state()


#state-transitions
func _enter_idle_state() -> void:
	pass
	
func _enter_run_state() -> void:
	anim.play("Run")
	runningParticles.emitting = true
	state = RUNNING
	holding_jump = false
	hold_time = 0.0
	can_jump = true 
	jumpbuffer = 0.0
	want_to_jump = false
	gravity = NORM_GRAVITY
	if prevoius_y_vel > 700 and not _on_down_slope():
		var particles = impact_scene.instance()
		particles.global_position = global_position + Vector2(5, 25)
		get_parent().add_child(particles)

func _enter_air_state(jumping: bool) -> void:
	if jumping:
		velocity.y = JUMP_STRENGHT
		can_jump = false
		holding_jump = true
	else:
		coyoteTimer.start()
	state = AIR
	jumpbuffer = 0.0
	anim.play("Jump")
	runningParticles.emitting = false


func _on_CoyoteTimer_timeout() -> void:
	can_jump = false
