var/process/open_space/OS_controller = null

/process/open_space
	var/list/open_spaces = list()

/process/open_space/setup()
	name = "openspace"
	schedule_interval = TRUE SECONDS // every second
	start_delay = 12
	OS_controller = src

/process/open_space/fire()
	for (var/turf/floor/broken_floor/T in open_spaces)
		T.update_icon()

/turf/floor/broken_floor/New()
	..()
	if (OS_controller)
		OS_controller.open_spaces += src

/turf/floor/broken_floor/Del()
	if (OS_controller)
		OS_controller.open_spaces -= src
	..()

/turf/floor/broken_floor/update_icon()
	overlays.Cut()
	var/turf/below = GetBelow(src)
	if (!isturf(below))
		below = get_turf(below)
	if (below)
		icon = below.icon
		icon_state = below.icon_state
		dir = below.dir
		color = below.color//rgb(127,127,127)
	//	overlays += below.overlays // for some reason this turns an open
	// space into plating.

		if (!istype(below,/turf/floor/broken_floor))
			// get objects
			var/image/o_img = list()
			for (var/obj/o in below)
				// ingore objects that have any form of invisibility
				if (o.invisibility) continue
				var/image/temp2 = image(o, dir=o.dir, layer = o.layer)
				temp2.plane = plane
				temp2.color = o.color//rgb(127,127,127)
				temp2.overlays += o.overlays
				o_img += temp2
			overlays += o_img

			var/image/over_OS_darkness = image('icons/turf/floors.dmi', "black_open")
			over_OS_darkness.plane = FLOOR_PLANE
			over_OS_darkness.layer = MOB_LAYER + 0.1
			overlays += over_OS_darkness

/turf/sky
	icon = 'icons/turf/sky.dmi'
	icon_state = ""
	name = "the sky"
	opacity = FALSE
	density = TRUE

/turf/floor/broken_floor
	name = "hole"
	icon = 'icons/turf/areas.dmi'
	icon_state = "black"
	density = FALSE

/turf/floor/broken_floor/sky
	name = "sky"
	density = FALSE
	icon = 'icons/turf/sky.dmi'
	icon_state = ""

/turf/floor/broken_floor/New()
	..()
	if (z > 1)
		floorbelowz = locate(x, y, z-1)
	else
		floorbelowz = locate(x, y, 1)

	spawn(5)
		update_icon()

	for(var/atom/movable/AM in src.contents)
		Entered(AM)

/turf/floor/broken_floor/Entered(atom/movable/A)
	. = ..()
	if (!A || !A.loc)
		return
	if (isobserver(A))
		return
	for (var/obj/covers/C in src)
		if (istype(C, /obj/covers))
			return
	if (floorbelowz)
		if (istype(A, /mob))
			A.z -= 1
			A.visible_message("[A] falls from the level above and slams into \the floor!", "You land on the floor.", "You hear a soft whoosh and a crunch.")
			if (istype(A, /mob/living/human))
				playsound(A.loc, 'sound/effects/gore/fallsmash.ogg', 50, TRUE)
				var/mob/living/human/H = A
				H.Stun(6)
				var/damage = 25
				H.apply_damage(rand(0, damage), BRUTE, "head")
				H.apply_damage(rand(0, damage), BRUTE, "chest")
				H.apply_damage(rand(0, damage), BRUTE, "l_leg")
				H.apply_damage(rand(0, damage), BRUTE, "r_leg")
				H.apply_damage(rand(0, damage), BRUTE, "l_arm")
				H.apply_damage(rand(0, damage), BRUTE, "r_arm")
				H.updatehealth()

		if (istype(A, /obj))
			if (istype(A, /obj/item/projectile) || istype(A, /obj/covers))
				return
			else
				A.z -= 1
				A.visible_message("\The [A] falls from the level above and slams into the floor!", "You hear something slam into the deck.")

/turf/floor/broken_floor/attackby(mob/user)
	var/your_dir = "NORTH"

	switch (user.dir)
		if (NORTH)
			your_dir = "NORTH"
		if (SOUTH)
			your_dir = "SOUTH"
		if (EAST)
			your_dir = "EAST"
		if (WEST)
			your_dir = "WEST"

	var/covers_time = 80

	if (ishuman(user))
		var/mob/living/human/H = user
		covers_time /= H.getStatCoeff("strength")
		covers_time /= (H.getStatCoeff("crafting") * H.getStatCoeff("crafting"))

	if (WWinput(user, "This will start building a floor cover [your_dir] of you.", "Floor Cover Construction", "Continue", list("Continue", "Stop")) == "Continue")
		visible_message("<span class='danger'>[user] starts constructing the floor cover.</span>", "<span class='danger'>You start constructing the floor cover.</span>")
		if (do_after(user, covers_time, user.loc))
			qdel(src)
			new/obj/covers/repairedfloor(get_step(user, user.dir), user)
			visible_message("<span class='danger'>[user] finishes placing the floor cover.</span>")
			if (ishuman(user))
				var/mob/living/human/H = user
				H.adaptStat("crafting", 3)
		return
	return