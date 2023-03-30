extends KinematicBody2D
class_name Player

signal dead(distance)

onready var anim = $AnimationPlayer
onready var coyoteTimer = $CoyoteTimer
onready var downSlopeRay = $DownSlopeRay
onready var distanceText = $HUD/DistanceText
onready var runningParticles = $RunningParticles
onready var jumpBuffer = $JumpBuffer
onready var jumpSound = $JumpSound

const MAX_ACC = 350
const NORM_GRAVITY = 2000
const MIN_GRAVITY = 700
const MAX_GRAVITY = 4200
const JUMP_STRENGHT = -800
const MAX_HOLD_TIME = 0.4;
const follow_slope_const = PI/4

var gravity := NORM_GRAVITY
var max_speed = 420.0
var prevoius_y_vel = 0
var can_jump := true
var want_to_jump := false
var holding_jump := false
var hold_time := 0.0
var acc := 250.0


var velocity := Vector2.ZERO
var distance_traveled := 0.0

enum {RUNNING, AIR, DEAD}

var state = RUNNING

onready var start_x = global_position.x

var impact_scene = preload("res://Scenes/ImpactSmoke.tscn")
var death_particles = preload("res://Scenes/PlayerDeadParticles.tscn")

func _physics_process(delta: float) -> void:
	match state:
		RUNNING: 
			_run_state(delta)
		AIR:
			_air_state(delta)
		DEAD:
			pass
			
	distance_traveled = (global_position.x - start_x) / 20.0
	distanceText.text = "Distance: " + str(round(distance_traveled)) + " m"
	if global_position.y > 620:
		enter_dead_state(false)

#general help functions
func _move_player(delta) -> void:
	prevoius_y_vel = velocity.y
	if _on_down_slope():
		velocity = velocity.move_toward(Vector2.RIGHT.rotated(follow_slope_const) * max_speed * 2.2, NORM_GRAVITY * delta)
	else:
		velocity.x = move_toward(velocity.x, max_speed, acc*delta)
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, 1000)
		
	velocity = move_and_slide_with_snap(velocity, Vector2.DOWN * 10,Vector2.UP,
										true, 4, deg2rad(50), true)
	
	_change_anim_speed_and_acc(velocity)


func _change_anim_speed_and_acc(velocity: Vector2) -> void:
	var xVelocityRatio = abs(velocity.x / max_speed)
	var playbackSpeed = 0.75 * xVelocityRatio + 0.5
	anim.playback_speed = playbackSpeed
	
	if velocity.x <= 0:
		acc = MAX_ACC
	elif is_on_floor():
		acc = max(abs(1 - xVelocityRatio) * MAX_ACC, 20)
	else:
		acc = max(abs(1 - xVelocityRatio) * MAX_ACC * 0.5, 20)

func _on_down_slope() -> bool:
	downSlopeRay.force_raycast_update()
	#return downSlopeRay.is_colliding()
	if downSlopeRay.is_colliding():
		var norm: Vector2 = downSlopeRay.get_collision_normal()
		if is_equal_approx(norm.angle(), -PI/4): #norm.angle() < -PI / 6.0 and norm.angle() > -PI / 3.0:
			return true
	return false



#state-functions
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
		jumpBuffer.start()
		
		
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
		
	if velocity.y > 0:
		anim.play("Fall")
	
	if is_on_floor():
		if want_to_jump:
			_enter_air_state(true)
		else:
			_enter_run_state()

#state-transitions
func _enter_run_state() -> void:
	anim.play("Run")
	runningParticles.emitting = true
	state = RUNNING
	holding_jump = false
	hold_time = 0.0
	can_jump = true 
	want_to_jump = false
	gravity = NORM_GRAVITY
	if prevoius_y_vel > 950 and not _on_down_slope():
		var particles = impact_scene.instance()
		particles.global_position = global_position + Vector2(5, 25)
		get_parent().add_child(particles)

func _enter_air_state(jumping: bool) -> void:
	if jumping:
		velocity.y = JUMP_STRENGHT
		can_jump = false
		holding_jump = true
		jumpSound.play()
	else:
		coyoteTimer.start()
	state = AIR
	anim.play("Jump")
	runningParticles.emitting = false

func enter_dead_state(spawn_particles: bool) -> void:
	state = DEAD
	visible = false
	distanceText.visible = false
	if spawn_particles:
		var p = death_particles.instance()
		p.emitting  = true 
		p.one_shot = true
		p.global_position = global_position + Vector2(-22, -15)
		get_parent().add_child(p)
		yield(get_tree().create_timer(0.4), "timeout")
	
	emit_signal("dead", round(distance_traveled))
	

func _on_CoyoteTimer_timeout() -> void:
	can_jump = false
	
func _on_JumpBuffer_timeout() -> void:
	want_to_jump = false
