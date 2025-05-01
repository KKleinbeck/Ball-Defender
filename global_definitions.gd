extends Node


const ballRadius: float = 10.
const boxesPerRow: int = 10


enum EntityType {Empty, Standard, Damage, TimeUp, Currency, PremiumCurrency, Charge}
enum State {RUNNING, HALTING, GAMEOVER}
var state: State = State.RUNNING

var adUnitID: String
var rewardInterstitialAd: RewardedInterstitialAd
var rewardInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback
var fullScreenContentCallback := FullScreenContentCallback.new()
var onUserEarnedRewardListener := OnUserEarnedRewardListener.new()


func _ready() -> void:
	MobileAds.initialize()
	
	if OS.get_name() == "Android":
		adUnitID = "ca-app-pub-3940256099942544/5354046379"
	elif OS.get_name() == "iOS":
		adUnitID = "ca-app-pub-3940256099942544/4411468910"
	
	rewardInterstitialAdLoadCallback = RewardedInterstitialAdLoadCallback.new()
	rewardInterstitialAdLoadCallback.on_ad_failed_to_load = func(adError: LoadAdError) -> void:
		print(adError.message)

	rewardInterstitialAdLoadCallback.on_ad_loaded = onAdLoaded
	
	fullScreenContentCallback.on_ad_clicked = func() -> void:
		print("on_ad_clicked")
	fullScreenContentCallback.on_ad_dismissed_full_screen_content = func() -> void:
		print("on_ad_dismissed_full_screen_content")
	fullScreenContentCallback.on_ad_failed_to_show_full_screen_content = func(_ad_error: AdError) -> void:
		print("on_ad_failed_to_show_full_screen_content")
	fullScreenContentCallback.on_ad_impression = func() -> void:
		print("on_ad_impression")
	fullScreenContentCallback.on_ad_showed_full_screen_content = func() -> void:
		print("on_ad_showed_full_screen_content")
	
	onUserEarnedRewardListener.on_user_earned_reward = func(rewarded_item : RewardedItem):
		print("on_user_earned_reward, rewarded_item: rewarded", rewarded_item.amount, rewarded_item.type)
	
	set_process(false)


func onAdLoaded(_rewardInterstitialAd: RewardedInterstitialAd) -> void:
	print("interstitial ad loaded" + str(_rewardInterstitialAd._uid))
	rewardInterstitialAd = _rewardInterstitialAd
	rewardInterstitialAd.full_screen_content_callback = fullScreenContentCallback


func loadRewardInterstitial() -> void:
	if rewardInterstitialAd:
		rewardInterstitialAd.destroy()
		rewardInterstitialAd = null
		
	rewardInterstitialAdLoadCallback = RewardedInterstitialAdLoadCallback.new()
	
	RewardedInterstitialAdLoader.new().load(adUnitID, AdRequest.new(), rewardInterstitialAdLoadCallback)


func showRewardInterstitial() -> void:
	if rewardInterstitialAd:
		rewardInterstitialAd.show(onUserEarnedRewardListener)


func updateCollisionEvent(collisionEvent: Dictionary, t: float, partner: String, partnerDetails,
						  collisionLocation: Vector2, postVelocity: Vector2) -> void:
	if collisionEvent["t"] < t:
		return 
	collisionEvent["t"] = t
	collisionEvent["partner"] = partner
	collisionEvent["partner details"] = partnerDetails
	collisionEvent["collision location"] = collisionLocation
	collisionEvent["post velocity"] = postVelocity


func updateCollisionEventFromGeometricData(collisionEvent: Dictionary,
										   partner: String,
										   geometricCollisionData:Dictionary) -> void:
	if collisionEvent["t"] < geometricCollisionData["t"]:
		return
	for key in geometricCollisionData:
		collisionEvent[key] = geometricCollisionData[key]
	collisionEvent["partner"] = partner


func updateGeometricCollision(geometricCollisionData:Dictionary, t: float,
							  partnerDetails: String,
							  collisionLocation: Vector2,
							  postVelocity: Vector2) -> void:
	if t < 0 or t > geometricCollisionData["t"]: return
	geometricCollisionData["t"] = t
	geometricCollisionData["partner details"] = partnerDetails
	geometricCollisionData["collision location"] = collisionLocation
	geometricCollisionData["post velocity"] = postVelocity
