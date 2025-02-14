/datum/quirk/no_clone
	name = "DNC"
	desc = "You have filed a Do Not Clone order, stating that you do not wish to be cloned. You can still be revived by other means."
	value = -2
	mob_trait = TRAIT_NO_CLONE
	medical_record_text = "Patient has a DNC (Do not clone) order on file, and cannot be cloned as a result."

/datum/quirk/no_guns
	name = "Fat-Fingered"
	desc = "Due to the shape of your hands, width of your fingers or just not having fingers at all, you're unable to fire the majority of guns."
	value = -2
	mob_trait = TRAIT_CHUNKYFINGERS
	gain_text = "<span class='notice'>Your fingers feel.. thick.</span>"
	lose_text = "<span class='notice'>Your fingers feel normal again.</span>"

/datum/quirk/illiterate
	name = "Illiterate"
	desc = "You can't read nor write, plain and simple."
	value = -1
	mob_trait = TRAIT_ILLITERATE
	gain_text = "<span class='notice'>The knowledge of how to read seems to escape from you.</span>"
	lose_text = "<span class='notice'>Written words suddenly make sense again."

/datum/quirk/flimsy
	name = "Flimsy"
	desc = "Your body is a little more fragile then most, decreasing total health by 20%."
	value = -2
	medical_record_text = "Patient has abnormally low capacity for injury."
	gain_text = "<span class='notice'>You feel like you could break with a single hit."
	lose_text = "<span class='notice'>You feel more durable."

/datum/quirk/flimsy/add()
	quirk_holder.maxHealth *= 0.8

/datum/quirk/flimsy/remove() //how do admins even remove traits?
	if(!quirk_holder)
		return
	quirk_holder.maxHealth *= 1.25

/datum/quirk/hypersensitive
	name = "Hypersensitive"
	desc = "For better or worse, everything seems to affect your mood more than it should."
	value = -1
	gain_text = "<span class='danger'>You seem to make a big deal out of everything.</span>"
	lose_text = "<span class='notice'>You don't seem to make a big deal out of everything anymore.</span>"
	mood_quirk = TRUE //yogs
	medical_record_text = "Patient demonstrates a high level of emotional volatility."

/datum/quirk/hypersensitive/add()
	var/datum/component/mood/mood = quirk_holder.GetComponent(/datum/component/mood)
	if(mood)
		mood.mood_modifier += 0.5

/datum/quirk/hypersensitive/remove()
	if(!quirk_holder)
		return
	var/datum/component/mood/mood = quirk_holder.GetComponent(/datum/component/mood)
	if(mood)
		mood.mood_modifier -= 0.5

/datum/quirk/masked_mook
	name = "Bane Syndrome"
	desc = "For some reason you don't feel well without wearing some kind of gas mask."
	gain_text = "<span class='danger'>You start feeling unwell without any gas mask on.</span>"
	lose_text = "<span class='notice'>You no longer have a need to wear some gas mask.</span>"
	value = -2
	mood_quirk = TRUE
	medical_record_text = "Patient feels more secure when wearing a gas mask."
	processing_quirk = TRUE
	var/mood_category = "masked_mook"

/datum/quirk/masked_mook/on_process()
	var/mob/living/carbon/human/H = quirk_holder
	var/obj/item/clothing/mask/gas/gasmask = H.get_item_by_slot(ITEM_SLOT_MASK)
	if(istype(gasmask))
		SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, mood_category, /datum/mood_event/masked_mook)
	else
		SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, mood_category, /datum/mood_event/masked_mook_incomplete)

/datum/quirk/masked_mook/on_spawn()
	. = ..()
	var/mob/living/carbon/human/H = quirk_holder
	var/obj/item/clothing/mask/gas/gasmask = new(get_turf(quirk_holder))
	H.equip_to_slot(gasmask, ITEM_SLOT_MASK)
	H.regenerate_icons()

/datum/quirk/well_trained
	name = "Well-trained"
	desc = "You absolutely love being dominated. The thought of someone with a stronger character than yours is enough to make you act up."
	value = -2
	gain_text = "<span class='notice'>You feel like being someone's pet</span>"
	lose_text = "<span class='notice'>You no longer feel like being a pet...</span>"
	processing_quirk = TRUE
	var/mood_category = "dom_trained"
	var/notice_delay = 0
	var/mob/living/carbon/human/last_dom

/datum/quirk/well_trained/add()
	. = ..()
	RegisterSignal(quirk_holder, COMSIG_PARENT_EXAMINE, .proc/on_examine_holder)

/datum/quirk/well_trained/remove()
	. = ..()
	UnregisterSignal(quirk_holder, COMSIG_PARENT_EXAMINE)

/datum/quirk/well_trained/proc/on_examine_holder(atom/source, mob/living/user, list/examine_list)
	SIGNAL_HANDLER

	if(!istype(user))
		return
	if(!user.has_quirk(/datum/quirk/dominant_aura))
		return
	examine_list += span_lewd("You can sense submissiveness irradiating from [quirk_holder.p_them()]")

/datum/quirk/well_trained/on_process()
	. = ..()
	if(!quirk_holder)
		return

	var/good_x = "pet"
	switch(quirk_holder.gender)
		if(MALE)
			good_x = "boy"
		if(FEMALE)
			good_x = "girl"

	//Check for possible doms with the dominant_aura quirk, and for the closest one if there is
	. = FALSE
	var/list/mob/living/carbon/human/doms = range(DOMINANT_DETECT_RANGE, quirk_holder)
	var/closest_distance
	for(var/mob/living/carbon/human/dom in doms)
		if(dom != quirk_holder && dom.has_quirk(/datum/quirk/dominant_aura))
			if(!closest_distance || get_dist(quirk_holder, dom) <= closest_distance)
				. = dom
				closest_distance = get_dist(quirk_holder, dom)

	//Return if no dom is found
	if(!.)
		last_dom = null
		return

	//Handle the mood
	var/datum/component/mood/mood = quirk_holder.GetComponent(/datum/component/mood)
	if(istype(mood.mood_events[mood_category], /datum/mood_event/dominant/good_boy))
		SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, mood_category, /datum/mood_event/dominant/good_boy)
	else
		SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, mood_category, /datum/mood_event/dominant/need)

	//Don't do anything if a previous dom was found
	if(last_dom)
		notice_delay = world.time + 15 SECONDS
		return

	last_dom = .

	if(notice_delay > world.time)
		return

	//Let them know they're near
	var/list/notices = list(
		"You feel someone's presence making you more submissive.",
		"The thought of being commanded floods you with lust.",
		"You really want to be called a good [good_x].",
		"Someone's presence is making you all flustered.",
		"You start getting excited and sweating."
	)

	to_chat(quirk_holder, span_lewd(pick(notices)))
	notice_delay = world.time + 15 SECONDS

/datum/quirk/dumb4cum
	name = "Dumb For Cum"
	desc = "You just like cum, it's heat, it's smell, it's... Taste."
	value = -3
	gain_text = "<span class='notice'>You suddenly start craving some seed inside of you.<span>"
	lose_text = "<span class='danger'>It didn't even taste that good, really!</span>"
	medical_record_text = "Patient seems to drool for seminal fluid."
	var/craving_after = 15 MINUTES
	var/timer

/datum/quirk/dumb4cum/on_spawn()
	. = ..()
	timer = addtimer(CALLBACK(src, .proc/crave), craving_after, TIMER_STOPPABLE)

/datum/quirk/dumb4cum/proc/crave()
	var/list/hungry_phrases = list(
									"Your stomach rumbles a bit and cum comes to your mind.",\
									"Urgh, you really should get some cum...",\
									"Some jizz wouldn't sit bad right now!",\
									"You're starting to long for more cum."
								  )
	to_chat(quirk_holder, "<span class='love'>[pick(hungry_phrases)]</span>")

	if(quirk_holder.stat == CONSCIOUS)
		quirk_holder.emote("sigh")
	ADD_TRAIT(quirk_holder, TRAIT_PACIFISM, type)
	ADD_TRAIT(quirk_holder, TRAIT_DUMB4CUM, type)
	SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, "cum_craving", /datum/mood_event/cum_craving)

/datum/quirk/dumb4cum/proc/uncrave()
	REMOVE_TRAIT(quirk_holder, TRAIT_PACIFISM, type)
	REMOVE_TRAIT(quirk_holder, TRAIT_DUMB4CUM, type)
	SEND_SIGNAL(quirk_holder, COMSIG_CLEAR_MOOD_EVENT, "cum_craving")
	SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, "cum_stuffed", /datum/mood_event/cum_stuffed)

	deltimer(timer)
	timer = null
	timer = addtimer(CALLBACK(src, .proc/crave), craving_after, TIMER_STOPPABLE)
