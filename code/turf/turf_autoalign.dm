
/* =================================================== */
/* -------------------- SIMULATED -------------------- */
/* =================================================== */

/turf/wall/auto
	icon = 'icons/turf/walls_auto.dmi'
	var/mod = null
	var/light_mod = null
	var/connect_overlay = 0 // do we have wall connection overlays, ex nornwalls?
	var/list/connects_to = list(/turf/wall/auto,/turf/wall/false_wall)
	var/list/connects_to_exceptions = list() // because connections now work by parent type searches, this is for when you don't want certain subtypes to connect
	var/list/connects_with_overlay = null
	var/list/connects_with_overlay_exceptions = list() // same as above comment
	var/image/connect_image = null
	var/tmp/connect_overlay_dir = 0
	var/connect_diagonal = 0 // 0 = no diagonal sprites, 1 = diagonal only if both adjacent cardinals are present, 2 = always allow diagonals
	var/d_state = 0

	color // lighter toned walls for easier use of color var
		icon = 'icons/turf/walls_auto_color.dmi'

	New()
		..()
		if (map_setting && ticker)
			src.update_neighbors()

		if (worldgen_hold)
			worldgen_candidates[worldgen_generation] += src
		else src.update_icon()

	generate_worldgen()
		src.update_icon()

	Del()
		src.RL_SetSprite(null)
		..()

	the_tuff_stuff
		explosion_resistance = 7
	// ty to somepotato for assistance with making this proc actually work right :I
	proc/update_icon()
		var/builtdir = 0
		if (connect_overlay && !islist(connects_with_overlay))
			connects_with_overlay = list()
		src.connect_overlay_dir = 0
		for (var/dir in cardinal)
			var/turf/T = get_step(src, dir)
			if (T && (istype(T, src.type)))
				builtdir |= dir
			else if (connects_to)
				for (var/i=1, i <= connects_to.len, i++)
					// if the turf appears in our connection list AND isn't in our exceptions...
					if (istype(T, connects_to[i]) && !(T.type in connects_to_exceptions))
						builtdir |= dir
						break
					// Search for non-turf atoms we can connect to
					var/atom/A = locate(connects_to[i]) in T
					if (!isnull(A))
						if (istype(A, /atom/movable))
							var/atom/movable/M = A
							if (!M.anchored)
								continue
						builtdir |= dir
						break
			if (connect_overlay && connects_with_overlay)
				for (var/i=1, i <= connects_with_overlay.len, i++)
					// if the turf appears in our overlay'd connection list, AND isn't in our exceptions, AND isn't... well, a copy of ourselves...
					if (istype(T, connects_with_overlay[i]) && !(T.type in connects_with_overlay_exceptions) && !(T.type == src.type))
						src.connect_overlay_dir |= dir
						break
					// Search for non-turf atoms we can connect to
					var/atom/A = locate(connects_with_overlay[i]) in T
					if (!isnull(A))
						if (istype(A, /atom/movable))
							var/atom/movable/M = A
							if (!M.anchored)
								continue
						src.connect_overlay_dir |= dir
		if (connect_diagonal)
			for (var/j = 1 to 4)
				if (connect_diagonal < 2 && ((builtdir & ordinal[j]) != ordinal[j]))
					continue
				var/turf/T = get_step(src, ordinal[j])
				var/dir = 8 << j
				if (T && (istype(T, src.type)))
					builtdir |= dir
				else if (connects_to)
					for (var/i=1, i <= connects_to.len, i++)
						// if the turf appears in our connection list AND isn't in our exceptions...
						if (istype(T, connects_to[i]) && !(T.type in connects_to_exceptions))
							builtdir |= dir
							break
						// Search for non-turf atoms we can connect to
						var/atom/A = locate(connects_to[i]) in T
						if (!isnull(A))
							if (istype(A, /atom/movable))
								var/atom/movable/M = A
								if (!M.anchored)
									continue
							builtdir |= dir
							break

		var/the_state = "[mod][builtdir]"
		if ( !(istype(src, /turf/wall/auto/jen)) && !(istype(src, /turf/wall/auto/reinforced/jen)) ) //please no more sprite, i drained my brain doing this
			src.icon_state += "[src.d_state ? "C" : null]"
		icon_state = the_state

		if (light_mod)
			src.RL_SetSprite("[light_mod][builtdir]")

		if (connect_overlay)
			if (src.connect_overlay_dir)
				if (!src.connect_image)
					src.connect_image = image(src.icon, "connect[src.connect_overlay_dir]")
				else
					src.connect_image.icon_state = "connect[src.connect_overlay_dir]"
				src.UpdateOverlays(src.connect_image, "connect")
			else
				src.UpdateOverlays(null, "connect")

	proc/update_neighbors()
		for (var/turf/wall/auto/T in orange(1,src))
			T.update_icon()
		for (var/obj/grille/G in orange(1,src))
			G.update_icon()

/turf/wall/auto/reinforced
	name = "reinforced wall"
	health = 300
	explosion_resistance = 7
	mod = "R"
	icon_state = "mapwall_r"
	connects_to = list(/turf/wall/auto/reinforced,/turf/wall/false_wall/reinforced)
	the_tuff_stuff
		explosion_resistance = 11
		desc = "Looks <em>way</em> tougher than a regular wall."

	color
		icon = 'icons/turf/walls_auto_color.dmi'

	get_desc()
		switch (src.d_state)
			if (0)
				. += "<br>Looks like disassembling it starts with snipping some of those reinforcing rods."
			if (1)
				. += "<br>Up next in this long journey is unscrewing the support lines."
			if (2)
				. += "<br>What'd really help at this point is unwelding the metal cover."
			if (3)
				. += "<br>Your prying eyes suggest prying off the metal cover you just unwelded."
			if (4)
				. += "<br>The latest wrench in your plans for wall disassembly appear to be some support rods."
			if (5)
				. += "<br>Is this wall okay? It's looking a little under the welder. Or maybe that's just its support rods."
			if (6)
				. += "<br>Almost! Just need to pry off the outer sheath. Which you've somehow been working around this whole time. <em>Somehow</em>."


	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/light_parts))
			src.attach_light_fixture_parts(user, W) // Made this a proc to avoid duplicate code (Convair880).
			return

		/* ----- Deconstruction ----- */
		if (src.d_state == 0 && issnippingtool(W) && isconstructionturf(src)) //If we never let em *start* decon the rest of these don't need to care
			actions.start(new /datum/action/bar/icon/wall_tool_interact(src, W, WALL_REMOVERERODS), user)
			return

		else if (src.d_state == 1 && isscrewingtool(W))
			actions.start(new /datum/action/bar/icon/wall_tool_interact(src, W, WALL_REMOVESUPPORTLINES), user)
			return

		else if (src.d_state == 2 && isweldingtool(W))
			if(!W:try_weld(user,1,-1,1,1))
				return
			actions.start(new /datum/action/bar/icon/wall_tool_interact(src, W, WALL_SLICECOVER), user)
			return

		else if (src.d_state == 3 && ispryingtool(W))
			actions.start(new /datum/action/bar/icon/wall_tool_interact(src, W, WALL_PRYCOVER), user)
			return

		else if (src.d_state == 4 && iswrenchingtool(W))
			actions.start(new /datum/action/bar/icon/wall_tool_interact(src, W, WALL_DETATCHSUPPORTRODS), user)
			return

		else if (src.d_state == 5 && isweldingtool(W))
			if(!W:try_weld(user,1,-1,1,1))
				return
			actions.start(new /datum/action/bar/icon/wall_tool_interact(src, W, WALL_REMOVESUPPORTRODS), user)
			return

		else if (src.d_state == 6 && ispryingtool(W))
			actions.start(new /datum/action/bar/icon/wall_tool_interact(src, W, WALL_PRYSHEATH), user)
			return


	/* ----- End Deconstruction ----- */

		else if (istype(W, /obj/item/device/key/haunted) && issimulatedturf(src)) //gonna guess this shouldn't happen in azones :)
			var/obj/item/device/key/haunted/H = W
			//Okay, create a temporary false wall.
			if (H.last_use && ((H.last_use + 300) >= world.time))
				boutput(user, "<span class='alert'>The key won't fit in all the way!</span>")
				return
			user.visible_message("<span class='alert'>[user] inserts [W] into [src]!</span>","<span class='alert'>The key seems to phase into the wall.</span>")
			H.last_use = world.time
			blink(src)
			var/turf/wall/false_wall/temp/fakewall = src.ReplaceWith(/turf/wall/false_wall/temp, FALSE, TRUE, FALSE, TRUE)
			fakewall.was_rwall = 1
			fakewall.opacity = 0
			fakewall.RL_SetOpacity(1) //Lighting rebuild.
			return

		else if (istype(W, /obj/item/sheet) && src.d_state)
			var/obj/item/sheet/S = W
			boutput(user, "<span class='notice'>Repairing wall.</span>")
			if (do_after(user, 2.5 SECONDS) && S.change_stack_amount(-1))
				src.d_state = 0
				src.icon_state = initial(src.icon_state)
				if (S.material)
					src.setMaterial(S.material)
				else
					src.setMaterial(getMaterial("steel"))
				boutput(user, "<span class='notice'>You repaired the wall.</span>")
				return

		else if (istype(W, /obj/item/grab))
			var/obj/item/grab/G = W
			if (!grab_smash(G, user))
				return ..(W, user)
			else
				return

		if (src.material)
			var/fail = 0
			if (src.material.hasProperty("stability") && src.material.getProperty("stability") < 15)
				fail = 1
			if (src.material.quality < 0) if(prob(abs(src.material.quality)))
				fail = 1
			if (fail)
				user.visible_message("<span class='alert'>You hit the wall and it [getMatFailString(src.material.material_flags)]!</span>","<span class='alert'>[user] hits the wall and it [getMatFailString(src.material.material_flags)]!</span>")
				playsound(src.loc, "sound/impact_sounds/Generic_Stab_1.ogg", 25, 1)
				del(src)
				return

		src.take_hit(W)

/turf/wall/auto/concrete
	icon = 'icons/turf/walls_concrete.dmi' //thank you Arborinus!!!
	connects_to = list(/turf/wall/auto/concrete, /turf/wall/auto/concrete/window) //probably just fine like this
	flags = ALWAYS_SOLID_FLUID

	explosion_resistance = 7 //tuff by default

	window
		name = "window"
#ifdef IN_MAP_EDITOR
		icon_state = "window-map"
#endif
		opacity = 0
		var/panel_icon = "window"
		var/overlay1 = null
		var/overlay2 = null

		New()
			..()
			src.overlays += image('icons/turf/walls_concrete.dmi', panel_icon)
			if(overlay1 != null)
				src.overlays += image('icons/turf/walls_concrete.dmi', overlay1)
			if(overlay2 != null)
				src.overlays += image('icons/turf/walls_concrete.dmi', overlay2)

	window/porthole
		name = "porthole"
		panel_icon = "porthole"

	window/barred
		overlay1 = "bars"

	window/frosted
		panel_icon = "window-frosted"

	window/frosted_barred
		panel_icon = "window-frosted"
		overlay1 = "bars"

	window/icy
		panel_icon = "window-frosted"
		overlay1 = "icicle"

	window/icy_barred
		panel_icon = "window-frosted"
		overlay1 = "bars"
		overlay2 = "icicle"

/turf/wall/auto/rivet
	icon = 'icons/turf/walls_rivet.dmi'
	connects_to = list(/turf/wall/auto/rivet, /turf/wall/auto/rivet/window)
	var/panel = TRUE
	var/image/overlay_glass = null
	var/image/overlay_trim = null

	New()
		..()
		if(prob(33)) // add some rust
			var/image/rust = image(src.icon, pick("rust1","rust2"))
			rust.appearance_flags = RESET_COLOR
			src.UpdateOverlays(rust, "rust")
		if((panel) && (prob(33))) // add a small extra bit for some variation
			var/image/panel = image(src.icon, pick("panel1","panel2","panel3"))
			panel.pixel_x = 0 + rand(-3,1)
			src.UpdateOverlays(panel, "panel")
		if((overlay_glass != null) && (overlay_trim != null)) // windows in 2 parts, glass and trim
			var/image/glass = image(src.icon, overlay_glass)
			var/image/trim = image(src.icon, overlay_trim)
			glass.appearance_flags = RESET_COLOR
			trim.appearance_flags = RESET_COLOR
			trim.color = src.color
			src.UpdateOverlays(glass, "glass")
			src.UpdateOverlays(trim, "trim")

	window
		panel = FALSE
		opacity = 0

	window/square
#ifdef IN_MAP_EDITOR
		icon_state = "icon_sq"
#endif
		overlay_glass = "windowsq_glass"
		overlay_trim = "windowsq_trim"

	window/porthole
#ifdef IN_MAP_EDITOR
		icon_state = "icon_port"
#endif
		overlay_glass = "windowp_glass"
		overlay_trim = "windowp_trim"

/turf/wall/auto/jen
	icon = 'icons/turf/walls_jen.dmi'
	light_mod = "wall-jen-"
	flags = ALWAYS_SOLID_FLUID | IS_PERSPECTIVE_FLUID
	connect_overlay = 1
	connects_to = list(/turf/wall/auto/supernorn, /turf/wall/auto/reinforced/supernorn,
	/turf/wall/false_wall, /obj/machinery/door, /obj/window, /obj/wingrille_spawn, /turf/wall/auto/reinforced/supernorn/yellow, /turf/wall/auto/reinforced/supernorn/blackred,
	/turf/wall/auto/jen, /turf/wall/auto/reinforced/jen)

	connects_with_overlay = list(/turf/wall/auto/reinforced/supernorn, /turf/wall/auto/supernorn,
	/turf/wall/false_wall/reinforced, /turf/wall/auto/shuttle, /turf/wall/auto/shuttle, /obj/machinery/door, /obj/window, /obj/wingrille_spawn, /turf/wall/auto/reinforced/supernorn/yellow, /turf/wall/auto/reinforced/supernorn/blackred,
	/turf/wall/auto/reinforced/jen)

	update_neighbors()
		..()
		for (var/obj/window/auto/O in orange(1,src))
			O.update_icon()

	the_tuff_stuff
		explosion_resistance = 7

	dark1
		color = "#dddddd"

	dark2
		color = "#bbbbbb"

	dark3
		color = "#999999"

	dark4
		color = "#777777"

	red
		color = "#ff9999"

	orange
		color = "#ffc599"

	brown
		color = "#d4ab8c"

	green
		color = "#9ec09e"

	yellow
		color = "#fff5a7"

	cyan
		color = "#86fbff"

	purple
		color = "#c5a8cc"

	blue
		color = "#87befd"

/turf/wall/auto/reinforced/jen
	icon = 'icons/turf/walls_jen.dmi'
	light_mod = "wall-jen-"
	flags = ALWAYS_SOLID_FLUID | IS_PERSPECTIVE_FLUID
	connect_overlay = 1
	connects_to = list(/turf/wall/auto/supernorn, /turf/wall/auto/reinforced/supernorn,
	/turf/wall/auto/jen, /turf/wall/auto/reinforced/jen,
	/turf/wall/false_wall, /obj/machinery/door, /obj/window, /obj/wingrille_spawn, /turf/wall/auto/reinforced/supernorn/yellow, /turf/wall/auto/reinforced/supernorn/blackred)

	connects_with_overlay = list(/turf/wall/auto/reinforced/supernorn,
	/turf/wall/auto/jen,
	/turf/wall/false_wall/reinforced, /turf/wall/auto/shuttle, /turf/wall/auto/shuttle, /obj/machinery/door, /obj/window, /obj/wingrille_spawn, /turf/wall/auto/reinforced/supernorn/yellow, /turf/wall/auto/reinforced/supernorn/blackred)

	the_tuff_stuff
		explosion_resistance = 3

	update_neighbors()
		..()
		for (var/obj/window/auto/O in orange(1,src))
			O.update_icon()

	dark1
		color = "#dddddd"

	dark2
		color = "#bbbbbb"

	dark3
		color = "#999999"

	dark4
		color = "#777777"

	red
		color = "#ff9999"

	orange
		color = "#ffc599"

	brown
		color = "#d4ab8c"

	green
		color = "#9ec09e"

	yellow
		color = "#fff5a7"

	cyan
		color = "#86fbff"

	purple
		color = "#c5a8cc"

	blue
		color = "#87befd"

/turf/wall/auto/supernorn
	icon = 'icons/turf/walls_supernorn_smooth.dmi'
	mod = "norn-"
	light_mod = "wall-"
	flags = ALWAYS_SOLID_FLUID | IS_PERSPECTIVE_FLUID
	connect_overlay = 1
	connect_diagonal = 1
	connects_to = list(/turf/wall/auto/supernorn, /turf/wall/auto/reinforced/supernorn,
	/turf/wall/false_wall, /obj/machinery/door, /obj/window, /obj/wingrille_spawn,
	/turf/wall/auto/jen, /turf/wall/auto/reinforced/jen, /turf/wall/auto/supernorn/wood)

	connects_with_overlay = list(/turf/wall/false_wall/reinforced, /turf/wall/auto/shuttle,
	/turf/wall/auto/jen, /obj/machinery/door, /obj/window, /obj/wingrille_spawn,
	 /turf/wall/auto/reinforced/jen, /turf/wall/auto/supernorn/wood)

	the_tuff_stuff
		explosion_resistance = 7

	update_neighbors()
		..()
		for (var/obj/window/auto/O in orange(1,src))
			O.update_icon()

/turf/wall/auto/reinforced/supernorn
	icon = 'icons/turf/walls_supernorn_smooth.dmi'
	mod = "norn-R-"
	light_mod = "wall-"
	flags = ALWAYS_SOLID_FLUID | IS_PERSPECTIVE_FLUID
	connect_overlay = 1
	connect_diagonal = 1
	connects_to = list(/turf/wall/auto/supernorn, /turf/wall/auto/reinforced/supernorn,
	/turf/wall/auto/jen, /turf/wall/auto/reinforced/jen,
	/turf/wall/false_wall/reinforced, /turf/wall/auto/shuttle, /obj/machinery/door,
	/obj/window, /obj/wingrille_spawn, /turf/wall/auto/reinforced/supernorn/yellow,
	/turf/wall/auto/reinforced/supernorn/blackred, /turf/wall/auto/reinforced/supernorn/orange,
	/turf/wall/auto/supernorn/wood)

	connects_with_overlay = list(/turf/wall/auto/jen, /turf/wall/auto/reinforced/jen,
	/turf/wall/false_wall, /turf/wall/auto/shuttle, /obj/machinery/door, /obj/window,
	/obj/wingrille_spawn, /turf/wall/auto/reinforced/paper, /turf/wall/auto/supernorn/wood)

	connects_with_overlay_exceptions = list(/turf/wall/false_wall/reinforced)

	the_tuff_stuff
		explosion_resistance = 11

	update_neighbors()
		..()
		for (var/obj/window/auto/O in orange(1,src))
			O.update_icon()

/turf/wall/auto/reinforced/supernorn/yellow
	icon = 'icons/turf/walls_manta.dmi'
#ifdef IN_MAP_EDITOR
	icon_state = "mapwall_r-Y"
#endif
	mod = "norn-Y-"
	light_mod = "wall-"
	flags = ALWAYS_SOLID_FLUID | IS_PERSPECTIVE_FLUID
	connect_overlay = 1
	connects_to = list(/turf/wall/auto/supernorn, /turf/wall/auto/reinforced/supernorn,
	/turf/wall/auto/jen, /turf/wall/auto/reinforced/jen,
	/turf/wall/false_wall/reinforced, /turf/wall/auto/shuttle, /obj/machinery/door, /obj/window, /obj/wingrille_spawn,
	/turf/wall/auto/supernorn/wood)

	connects_with_overlay = list(/turf/wall/auto/jen, /turf/wall/auto/reinforced/jen,
	/turf/wall/false_wall, /turf/wall/auto/shuttle, /obj/machinery/door, /obj/window, /obj/wingrille_spawn,
	/turf/wall/auto/supernorn/wood)

/turf/wall/auto/reinforced/supernorn/orange
	icon = 'icons/turf/walls_manta.dmi'
#ifdef IN_MAP_EDITOR
	icon_state = "mapwall_r-O"
#endif
	mod = "norn-O-"
	light_mod = "wall-"
	flags = ALWAYS_SOLID_FLUID | IS_PERSPECTIVE_FLUID
	connect_overlay = 1
	explosion_resistance = 11
	connects_to = list(/turf/wall/auto/supernorn, /turf/wall/auto/reinforced/supernorn,
	/turf/wall/auto/jen, /turf/wall/auto/reinforced/jen,
	/turf/wall/false_wall/reinforced, /turf/wall/auto/shuttle, /obj/machinery/door, /obj/window, /obj/wingrille_spawn,
	/turf/wall/auto/supernorn/wood)

	connects_with_overlay = list(/turf/wall/auto/jen, /turf/wall/auto/reinforced/jen,
	/turf/wall/false_wall, /turf/wall/auto/shuttle, /obj/machinery/door, /obj/window, /obj/wingrille_spawn,
	/turf/wall/auto/supernorn/wood)

/turf/wall/auto/reinforced/supernorn/blackred
	icon = 'icons/turf/walls_manta.dmi'
#ifdef IN_MAP_EDITOR
	icon_state = "mapwall_r-BR"
#endif
	mod = "norn-BR-"
	light_mod = "wall-"
	flags = ALWAYS_SOLID_FLUID | IS_PERSPECTIVE_FLUID
	connect_overlay = 1
	explosion_resistance = 11
	connects_to = list(/turf/wall/auto/supernorn, /turf/wall/auto/reinforced/supernorn,
	/turf/wall/auto/jen, /turf/wall/auto/reinforced/jen,
	/turf/wall/false_wall/reinforced, /turf/wall/auto/shuttle, /obj/machinery/door, /obj/window, /obj/wingrille_spawn,
	/turf/wall/auto/supernorn/wood)

	connects_with_overlay = list(/turf/wall/auto/jen, /turf/wall/auto/reinforced/jen,
	/turf/wall/false_wall, /turf/wall/auto/shuttle, /obj/machinery/door, /obj/window, /obj/wingrille_spawn,
	/turf/wall/auto/supernorn/wood)

/turf/wall/auto/reinforced/paper
	icon = 'icons/turf/walls_paper.dmi'
	connects_to = list(/turf/wall/auto/reinforced/paper, /turf/wall/auto/reinforced/supernorn, /turf/wall/auto, /obj/table/reinforced/bar/auto, /obj/window, /obj/wingrille_spawn)
	connects_with_overlay = list(/obj/table/reinforced/bar/auto)

	update_neighbors()
		..()
		for (var/obj/window/auto/O in orange(1,src))
			O.update_icon()
/turf/wall/auto/supernorn/wood
	icon = 'icons/turf/walls_wood.dmi'
	mod = "norn-W-"
	light_mod = "wall-"
	flags = ALWAYS_SOLID_FLUID | IS_PERSPECTIVE_FLUID
	connect_overlay = 1
	connects_to = list(/turf/wall/auto/supernorn, /turf/wall/auto/reinforced/supernorn,
	/turf/wall/false_wall, /obj/machinery/door, /obj/window, /obj/wingrille_spawn,
	/turf/wall/auto/jen, /turf/wall/auto/reinforced/jen, /turf/wall/auto/supernorn/wood)

	connects_with_overlay = list(/turf/wall/auto/supernorn, /turf/wall/auto/reinforced/supernorn,
	/turf/wall/false_wall, /turf/wall/false_wall/reinforced, /obj/machinery/door, /obj/window, /obj/wingrille_spawn,
	/turf/wall/auto/jen, /turf/wall/auto/reinforced/jen)

	update_neighbors()
		..()
		for (var/obj/window/auto/O in orange(1,src))
			O.update_icon()

/turf/wall/auto/gannets
	icon = 'icons/turf/walls_destiny.dmi'
	connects_to = list(/turf/wall/auto/gannets, /turf/wall/false_wall)
	the_tuff_stuff
		explosion_resistance = 7
/turf/wall/auto/marsoutpost
	icon = 'icons/turf/walls_marsoutpost.dmi'
	light_mod = "wall-"
	connect_overlay = 1
	connects_to = list(/turf/wall/auto/supernorn, /turf/wall/auto/reinforced/supernorn,
	/turf/wall/false_wall, /obj/machinery/door, /obj/window, /turf/wall/auto/supernorn/wood)

	connects_with_overlay = list(/turf/wall/auto/reinforced/supernorn,
	/turf/wall/false_wall/reinforced, /obj/machinery/door, /obj/window,
	/turf/wall/auto/supernorn/wood)

	update_neighbors()
		..()
		for (var/obj/window/auto/O in orange(1,src))
			O.update_icon()

/turf/wall/auto/reinforced/gannets
	icon = 'icons/turf/walls_destiny.dmi'
	connects_to = list(/turf/wall/auto/reinforced/gannets, /turf/wall/false_wall/reinforced)











/* ===================================================== */
/* -------------------- UNSIMULATED -------------------- */
/* ===================================================== */

// I should really just have the auto-wall stuff on the base /turf so there's less copy/paste code shit going on
// but that will have to wait for another day so for now, copy/paste it is
/* ATMOSSIMSTODO - I presume all this is basically duplicate, but maybe check?
/turf/wall/auto
	icon = 'icons/turf/walls_auto.dmi'
	var/mod = null
	var/light_mod = null
	var/connect_overlay = 0 // do we have wall connection overlays, ex nornwalls?
	var/list/connects_to = list(/turf/wall/auto)
	var/list/connects_to_exceptions = null
	var/list/connects_with_overlay = null
	var/list/connects_with_overlay_exceptions = null
	var/image/connect_image = null
	var/d_state = 0
	var/connect_diagonal = 0 // 0 = no diagonal sprites, 1 = diagonal only if both adjacent cardinals are present, 2 = always allow diagonals

	New()
		..()
		if (map_setting && ticker)
			src.update_neighbors()
		if (current_state > GAME_STATE_WORLD_INIT)
			SPAWN_DBG(0) //worldgen overrides ideally
				src.update_icon()

		else
			worldgen_candidates[src] = 1

	generate_worldgen()
		src.update_icon()

	Del()
		src.RL_SetSprite(null)
		..()


	proc/update_icon()
		var/builtdir = 0
		var/overlaydir = 0
		if (connect_overlay && !islist(connects_with_overlay))
			connects_with_overlay = list()
		for (var/dir in cardinal)
			var/turf/T = get_step(src, dir)
			if (!T)
				continue
			if (T && (T.type == src.type || (T.type in connects_to)))
				builtdir |= dir
			else if (connects_to)
				for (var/i=1, i <= connects_to.len, i++)
					var/atom/A = locate(connects_to[i]) in T
					if (!isnull(A))
						if (istype(A, /atom/movable))
							var/atom/movable/M = A
							if (!M.anchored)
								continue
						builtdir |= dir
						break
			if (connect_overlay && connects_with_overlay)
				if (T.type in connects_with_overlay)
					overlaydir |= dir
				else
					for (var/i=1, i <= connects_with_overlay.len, i++)
						var/atom/A = locate(connects_with_overlay[i]) in T
						if (!isnull(A))
							if (istype(A, /atom/movable))
								var/atom/movable/M = A
								if (!M.anchored)
									continue
							overlaydir |= dir
		if (connect_diagonal)
			for (var/j = 1 to 4)
				if (connect_diagonal < 2 && ((builtdir & ordinal[j]) != ordinal[j]))
					continue
				var/turf/T = get_step(src, ordinal[j])
				var/dir = 8 << j
				if (T && (istype(T, src.type)))
					builtdir |= dir
				else if (connects_to)
					for (var/i=1, i <= connects_to.len, i++)
						// if the turf appears in our connection list AND isn't in our exceptions...
						if (istype(T, connects_to[i]) && !(T.type in connects_to_exceptions))
							builtdir |= dir
							break
						// Search for non-turf atoms we can connect to
						var/atom/A = locate(connects_to[i]) in T
						if (!isnull(A))
							if (istype(A, /atom/movable))
								var/atom/movable/M = A
								if (!M.anchored)
									continue
							builtdir |= dir
							break

		src.icon_state = "[mod][builtdir][src.d_state ? "C" : null]"
		if (light_mod)
			src.RL_SetSprite("[light_mod][builtdir]")

		if (connect_overlay)
			if (overlaydir)
				if (!src.connect_image)
					src.connect_image = image(src.icon, "connect[overlaydir]")
				else
					src.connect_image.icon_state = "connect[overlaydir]"
				src.UpdateOverlays(src.connect_image, "connect")
			else
				src.UpdateOverlays(null, "connect")

	proc/update_neighbors()
		for (var/turf/wall/auto/T in orange(1,src))
			T.update_icon()
		for (var/obj/grille/G in orange(1,src))
			G.update_icon()

/turf/wall/auto/reinforced
	name = "reinforced wall"
	mod = "R"
	icon_state = "mapwall_r"
	connects_to = list(/turf/wall/auto/reinforced)

/turf/wall/auto/supernorn
	icon = 'icons/turf/walls_supernorn_smooth.dmi'
	light_mod = "wall-"
	mod = "norn-"
	flags = ALWAYS_SOLID_FLUID | IS_PERSPECTIVE_FLUID
	connect_overlay = 1
	connect_diagonal = 1
	connects_to = list(/turf/wall/auto/supernorn, /turf/wall/auto/reinforced/supernorn, /obj/machinery/door,
	/obj/window)
	connects_with_overlay = list(/obj/machinery/door, /obj/window)

/turf/wall/auto/reinforced/supernorn
	icon = 'icons/turf/walls_supernorn_smooth.dmi'
	light_mod = "wall-"
	mod = "norn-R-"
	flags = ALWAYS_SOLID_FLUID | IS_PERSPECTIVE_FLUID
	connect_overlay = 1
	connect_diagonal = 1
	connects_to = list(/turf/wall/auto/supernorn, /turf/wall/auto/reinforced/supernorn, /obj/machinery/door,
	/obj/window)
	connects_with_overlay = list(/obj/machinery/door, /obj/window)

/turf/wall/auto/gannets
	icon = 'icons/turf/walls_destiny.dmi'
	connects_to = list(/turf/wall/auto/gannets)

/turf/wall/auto/reinforced/gannets
	icon = 'icons/turf/walls_destiny.dmi'
	connects_to = list(/turf/wall/auto/reinforced/gannets)
*/
/turf/wall/auto/virtual
	icon = 'icons/turf/walls_destiny.dmi'
//	icon = 'icons/turf/walls_virtual.dmi'
	connects_to = list(/turf/wall/auto/virtual)
	name = "virtual wall"
	desc = "that sure is a wall, yep."

/turf/wall/auto/coral
	New()
		..()
		setMaterial(getMaterial("coral"))

// lead wall resprite by skeletonman0.... hooray for smoothwalls!
ABSTRACT_TYPE(turf/wall/auto/lead)
/turf/wall/auto/lead
	name = "lead wall"
	icon = 'icons/turf/walls_lead.dmi'
	light_mod = "wall-"
	flags = ALWAYS_SOLID_FLUID | IS_PERSPECTIVE_FLUID
	connect_overlay = 1
	connect_diagonal = 1
	connects_to = list(/turf/wall/auto/lead, /obj/machinery/door, /obj/window, /turf/wall/, /turf/wall/false_wall/,
	/turf/wall/setpieces/leadwindow, /turf/wall/false_wall/centcom)
	connects_with_overlay = list(/obj/machinery/door, /obj/window)

/turf/wall/auto/lead/blue
	icon_state = "mapiconb"
	mod = "leadb-"

/turf/wall/auto/lead/gray
	icon_state = "mapicong"
	mod = "leadg-"

/turf/wall/auto/lead/white
	icon_state = "mapiconw"
	mod = "leadw-"

/datum/action/bar/icon/wall_tool_interact
	id = "wall_tool_interact"
	//interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_STUNNED
	duration = 5 SECONDS
	icon_state = "working"

	var/turf/wall/auto/the_wall
	var/obj/item/the_tool
	var/interaction = WALL_REMOVERERODS

	New(var/obj/table/wall, var/obj/item/tool, var/interact, var/duration_i)
		..()
		if (wall)
			the_wall = wall
			//not a big fan of this actionbar implementation but this lets us mess with multiple walls at once again
			place_to_put_bar = wall
		if (usr)
			owner = usr
		if (tool)
			the_tool = tool
			icon = the_tool.icon
			icon_state = the_tool.icon_state
		if (interact)
			interaction = interact
		if (duration_i)
			duration = duration_i
		if (ishuman(owner))
			var/mob/living/carbon/human/H = owner
			if (H.traitHolder.hasTrait("training_engineer"))
				duration = round(duration / 2)

	onUpdate()
		..()
		if (the_wall == null || the_tool == null || owner == null || get_dist(owner, the_wall) > 1)
			interrupt(INTERRUPT_ALWAYS)
			return
		var/mob/source = owner
		if (istype(source) && (the_tool != source.equipped()))
			interrupt(INTERRUPT_ALWAYS)
			return

	onStart()
		..()
		var/message = ""
		switch (interaction)
			if (WALL_REMOVERERODS)
				message = "Removing some reinforcing rods."
				playsound(the_wall, "sound/items/Wirecutter.ogg", 100, 1)
			if (WALL_REMOVESUPPORTLINES)
				message = "Removing support lines."
				playsound(the_wall, "sound/items/Screwdriver.ogg", 100, 1)
			if (WALL_SLICECOVER)
				message = "Slicing metal cover."
			if (WALL_REMOVESUPPORTRODS)
				message = "Removing support rods."
			if (WALL_PRYCOVER)
				message = "Prying cover off."
				playsound(the_wall, "sound/items/Crowbar.ogg", 100, 1)
			if (WALL_PRYSHEATH)
				message = "Prying outer sheath off."
				playsound(the_wall, "sound/items/Crowbar.ogg", 100, 1)
			if (WALL_DETATCHSUPPORTRODS)
				playsound(the_wall, "sound/items/Ratchet.ogg", 100, 1)
				message = "Detaching support rods."
		owner.visible_message("<span class='notice'>[message].</span>")

	onEnd()
		..()
		var/message = ""
		switch (interaction)
			if (WALL_REMOVERERODS)
				message = "You remove some reinforcing rods."
				var/atom/A = new /obj/item/rods( the_wall )
				if (the_wall.material)
					A.setMaterial(the_wall.material)
				else
					A.setMaterial(getMaterial("steel"))
				the_wall.d_state = 1
				the_wall.update_icon()
			if (WALL_REMOVESUPPORTLINES)
				message = "You removed the support lines."
				the_wall.d_state = 2
			if (WALL_SLICECOVER)
				message = "You removed the metal cover."
				the_wall.d_state = 3
			if (WALL_REMOVESUPPORTRODS)
				message = "You removed the support rods."
				the_wall.d_state = 6
				var/atom/A = new /obj/item/rods( the_wall )
				if (the_wall.material)
					A.setMaterial(the_wall.material)
				else
					A.setMaterial(getMaterial("steel"))
			if (WALL_PRYCOVER)
				message = "You removed the cover."
				the_wall.d_state = 4
			if (WALL_PRYSHEATH)
				message = "You removed the outer sheath."
				logTheThing("station", owner, null, "dismantles a Reinforced Wall in [owner.loc.loc] ([showCoords(owner.x, owner.y, owner.z)])")
				the_wall.dismantle_wall()
			if (WALL_DETATCHSUPPORTRODS)
				message = "You detach the support rods."
				the_wall.d_state = 5
		owner.visible_message("<span class='notice'>[message].</span>")
