/obj/machinery/crusher
	name = "crusher unit"
	desc = "Breaks things down into metal/glass/waste"
	density = 1
	icon = 'icons/obj/scrap.dmi'
	icon_state = "Crusher_1"
	layer = MOB_LAYER + 1
	anchored = 1.0
	mats = 20
	is_syndicate = 1
	event_handler_flags = USE_FLUID_ENTER | USE_CANPASS
	var/osha_prob = 40 //How likely it is anyone touching it is to get dragged in
	var/list/poking_jerks = null //Will be a list if need be

	var/active = 0

	var/last_sfx = 0

	var/industrial = FALSE

/obj/machinery/crusher/Bumped(atom/AM)
	var/tm_amt = 0
	var/tg_amt = 0
	var/tw_amt = 0
	var/bblood = 0

	if(istype(AM,/obj/item/scrap))
		var/obj/O = AM
		O.set_loc(src.loc)
		return

	if(world.timeofday - AM.last_bumped <= 60)
		return

	if(ismob(AM))
		var/mob/M = AM
		M.set_loc(src.loc)
		for(var/obj/O in M.contents)
			if(isobj(O))
				tm_amt += O.m_amt
				tg_amt += O.g_amt
				tw_amt += O.w_amt
				if(iscarbon(M))
					tw_amt += 5000
					bblood = 2
				else if(issilicon(M))
					tm_amt += 5000
					tg_amt += 1000
			qdel(O)
		logTheThing("combat", M, null, "is ground up in a crusher at [log_loc(src)].")
		M.gib()
		#ifdef DATALOGGER
		game_stats.Increment("workplacesafety")
		#endif
	else if(isobj(AM))
		var/obj/B = AM
		tm_amt += B.m_amt
		tg_amt += B.g_amt
		tw_amt += B.w_amt
		for(var/obj/O in AM.contents)
			if(isobj(O))
				tm_amt += O.m_amt
				tg_amt += O.g_amt
				tw_amt += O.w_amt
			qdel(O)
	else
		return

	if (world.time > last_sfx + 5)
		playsound(src.loc, 'sound/items/mining_drill.ogg', 40, 1,0,0.8)
		last_sfx = world.time

	var/obj/item/scrap/S = new(get_turf(src))
	S.blood = bblood
	S.set_components(tm_amt,tg_amt,tw_amt)
	qdel(AM)
	//else
		//if(tw_amt > tm_amt || tw_amt > tg_amt)
			//var/obj/item/scrap/S = new(get_turf(src))
			//S.blood = bblood
			//S.set_components(tm_amt,tg_amt,tw_amt)
			//qdel(AM)
		//else if(tm_amt >= tg_amt)
			//var/obj/item/raw_material/scrap_metal/S = new(get_turf(src))
			//qdel(AM)
		//else
			//var/obj/item/raw_material/shard/glass/S = new(get_turf(src))
			//qdel(AM)
//		step(S,2)
	return


/obj/machinery/crusher/attack_hand(mob/user)
	if(!user || user.stat || get_dist(user,src)>1 || istype(user, /mob/dead/aieye)) //No unconscious / dead / distant users
		return

	//Daring text showing how BRAVE THIS PERSON IS!!!
	if(new_poker(user)) //Alright, this person is not currently touching the crusher

		user.visible_message("<span class='combat bold'>[user] [pick_string("descriptors.txt", "crusherpoke")] the [src]!</span>")
		if(prob(osha_prob)) //RIP you.
			user.canmove = 0
			user.anchored = 1
			sleep(5) //Give it a little time
			if(user) //Gotta make sure they haven't moved since last time
				poking_jerks -= user
				user.visible_message("<span class='combat bold'>...and gets pulled in! SHIT!!</span>")
				user.emote("scream")
				user.set_loc(get_turf(src)) //So it looks like they're actually pulled in
				src.Bumped(user)
				if(user) //Still here somehow?
					user.gib() //Not any more you aren't.
		else //Whew
			//So that we can restore their proper values after
			var/cmn = user.canmove
			var/anc = user.anchored
			//To prevent them moving away.
			user.canmove = 0
			user.anchored = 1
			interact_particle(user,src)
			sleep(5)
			if(user) //Still here?
				poking_jerks -= user
				user.visible_message("<span class='combat bold'>[pick_string("descriptors.txt", "crusherbrave")]</span>")
				user.canmove = cmn
				user.anchored = anc
	else //Oh, they are still touching the crusher.
		poking_jerks -= user
		user.visible_message("<span class='combat bold'>[user] jams [his_or_her(user)] entire arm into \the [src] in a shocking display of bravery! They are promptly dragged into it! FUCK!!</span>")
		user.emote("scream")
		user.set_loc(get_turf(src)) //So it looks like they're actually pulled in
		src.Bumped(user)
		if(user) //Still here somehow?
			user.gib() //Not any more you aren't.

/obj/machinery/crusher/proc/new_poker(var/mob/jerk)
	if(!islist(poking_jerks))
		poking_jerks = list(jerk)
	else if(poking_jerks.Find(jerk))
		return 0
	else
		poking_jerks += jerk

	return 1

/obj/machinery/crusher/process()
	..()
	if(status & (NOPOWER|BROKEN))	return
	use_power(500)

/obj/machinery/crusher/throw_impact(atom/hit_atom, datum/thrown_thing/thr)
	..()
	if (!hit_atom)
		return
	var/area/AR = get_area(hit_atom)
	if(AR?.sanctuary)
		return
	if(istype(hit_atom, /obj/machinery/crusher))
		return
	Bumped(hit_atom)


/obj/machinery/crusher/industrialcrusher
	name = "industrial crusher unit"
	desc = "Efficiently breaks down most matter, reducing it to its base materials."
	icon = 'icons/obj/scrap.dmi' //make it have like, orange and white tape around it or something idk i'll do it later
	icon_state = "Crusher_1"
	mats = 50
	osha_prob = 90 //How likely it is anyone touching it is to get dragged in

	industrial = TRUE
