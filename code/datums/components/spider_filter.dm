var/global/list/image/spider_filter_images

/datum/component/spider_filter_item
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/image/filter_image

/datum/component/spider_filter_item/Initialize()
	SHOULD_CALL_PARENT(1)
	..()

	src.filter_image = image('icons/effects/spider_filter.dmi', null, "pider")
	src.filter_image.override = 1

	if(isnull(global.spider_filter_images))
		global.spider_filter_images = list()

	global.spider_filter_images += src.filter_image
	for(var/mob/M as anything in by_cat[TR_CAT_SPIDER_FILTER_MOBS])
		M.client?.images += src.filter_image

	src.filter_image.loc = parent

/datum/component/spider_filter_item/disposing()
	global.spider_filter_images -= src.filter_image
	for(var/mob/M as anything in by_cat[TR_CAT_SPIDER_FILTER_MOBS])
		M.client?.images -= src.filter_image
	qdel(src.filter_image)
	. = ..()

// todo: persist this pref?
/mob/verb/hide_spiders()
	set desc = "Replace spiders with a text 'SPIDER' icon"
	set name = "Toggle Hide Spiders"

	var/client/client = src.client

	if(!client)
		return

	if(!client.hidden_spiders)
		client.hidden_spiders = TRUE
		for(var/image/I as anything in global.spider_filter_images)
			src.client.images += I
		boutput(src, "<span class='notice'>Spiders <b>Hidden</b>. They can still hurt you.</span>")
	else
		client.hidden_spiders = FALSE
		for(var/image/I as anything in global.spider_filter_images)
			src.client.images -= I
		boutput(src, "<span class='notice'>Spiders <b>Unhidden</b>.</span>")
