extends Node2D


func showAndPlay() -> void:
	visible = true
	$AnimationPlayer.play("LoadingAnimation")


func hideAndPause() -> void:
	visible = false
	$AnimationPlayer.pause("LoadingAnimation")
