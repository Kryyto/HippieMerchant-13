/datum/status_effect/ghoul
	id = "ghoul"
	status_type = STATUS_EFFECT_UNIQUE
	duration = -1
	alert_type = /atom/movable/screen/alert/status_effect/ghoul

	/// The new max health value set for the ghoul, if supplied
	var/new_max_health
	/// Reference to the master of the ghoul's mind
	var/datum/mind/master_mind
	/// An optional callback invoked when a ghoul is made (on_apply)
	var/datum/callback/on_made_callback
	/// An optional callback invoked when a goul is unghouled (on_removed)
	var/datum/callback/on_lost_callback

/datum/status_effect/ghoul/Destroy()
	master_mind = null
	QDEL_NULL(on_made_callback)
	QDEL_NULL(on_lost_callback)
	return ..()

/datum/status_effect/ghoul/on_creation(
	mob/living/new_owner,
	new_max_health,
	datum/mind/master_mind,
	datum/callback/on_made_callback,
	datum/callback/on_lost_callback,
)

	src.new_max_health = new_max_health
	src.master_mind = master_mind
	src.on_made_callback = on_made_callback
	src.on_lost_callback = on_lost_callback

	. = ..()

	if(master_mind)
		linked_alert.desc += " You are an eldritch monster reanimated to serve its master, [master_mind]."
	if(isnum(new_max_health))
		if(new_max_health > initial(new_owner.maxHealth))
			linked_alert.desc += " You are stronger in this form."
		else
			linked_alert.desc += " You are more fragile in this form."

/datum/status_effect/ghoul/on_apply()
	if(!ishuman(owner))
		return FALSE

	var/mob/living/carbon/human/human_target = owner

	RegisterSignal(human_target, COMSIG_LIVING_DEATH, .proc/remove_ghoul_status)
	human_target.revive(full_heal = TRUE, admin_revive = TRUE)

	if(new_max_health)
		human_target.setMaxHealth(new_max_health)
		human_target.health = new_max_health

	on_made_callback?.Invoke(human_target)
	human_target.become_husk(MAGIC_TRAIT)
	human_target.faction |= FACTION_HERETIC

	if(human_target.mind)
		var/datum/antagonist/heretic_monster/heretic_monster = human_target.mind.add_antag_datum(/datum/antagonist/heretic_monster)
		heretic_monster.set_owner(master_mind)

	return TRUE

/datum/status_effect/ghoul/on_remove()
	remove_ghoul_status()
	return ..()

/// Removes the ghoul effects from our owner and returns them to normal.
/datum/status_effect/ghoul/proc/remove_ghoul_status(datum/source)
	SIGNAL_HANDLER

	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/human_target = owner

	if(new_max_health)
		human_target.setMaxHealth(initial(human_target.maxHealth))

	on_lost_callback?.Invoke(human_target)
	human_target.cure_husk(MAGIC_TRAIT)
	human_target.faction -= FACTION_HERETIC
	human_target.mind?.remove_antag_datum(/datum/antagonist/heretic_monster)

	UnregisterSignal(human_target, COMSIG_LIVING_DEATH)
	if(!QDELETED(src))
		qdel(src)

/atom/movable/screen/alert/status_effect/ghoul
	name = "Flesh Servant"
	desc = "You are a Ghoul! A eldritch monster reanimated to serve its master."
	icon_state = "mind_control"
