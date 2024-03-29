/* Copyright (c) 2007 by Errata Security, All Rights Reserved
 * Programer(s): Robert David Graham [rdg]
 */
#include "parser.h"
#include "ferret.h"
#include "netframe.h"
#include "formats.h"
#include "module/housekeeping.h"
#include "module/wificrc.h"

#include <ctype.h>
#include <string.h>

unsigned global_packet_count = 0;

/**
 * This is the entry point into the packet parsers.
 *
 * I call this "layer 1", because the ethernet headers and such are still essentially layer-2.
 * At this layer, I just switch on link-type (raw WiFi or Ethernet).
 */
void process_frame(struct Ferret *ferret, struct NetFrame *frame, const unsigned char *px, unsigned length)
{
	unsigned i;

	global_packet_count++;

	/* Record the current time */
	if (ferret->now != (time_t)frame->time_secs) {
		ferret->now = (time_t)frame->time_secs;

		if (ferret->first == 0)
			ferret->first = frame->time_secs;

		/*
		 * Do housekeeping tasks
		 */
		for (i=0; i<ferret->engine_count; i++) {
			struct FerretEngine *engine = ferret->eng[i];
			if (engine == NULL)
				continue;

			if (engine->last_activity != (time_t)frame->time_secs) {
				engine->last_activity = (time_t)frame->time_secs;
				housekeeping_timeout(engine->housekeeper, frame->time_secs, frame);
			}
		}

		if (ferret->cfg.hamster_mode) {
			fprintf(stdout, "Packets: %u\n\n", global_packet_count);
			fflush(stdout);
		}
	}

	/* Clear the information that we will set in the frame */
	//ferret->frame.flags2 = 0;
	frame->flags.clear = 0;
	ferret->something_new_found = 0;

	/* Try to check FCS */
	if (ferret->linktype == 105 && frame->captured_length == frame->original_length) {
		if (frame->frame_number == 1)
			ferret->fcs_successes = 0;

		if (wifi_validate_fcs(px, length)) {
			ferret->statistics.fcs_good++;
			ferret->fcs_successes++;
			
			if (ferret->fcs_successes > frame->frame_number/20 || ferret->cfg.interface_checkfcs) {
				length -= 4;
				frame->captured_length -= 4; /*so we don't include it when writing out the packets */
				frame->original_length -= 4; /*so we don't include it when writing out the packets */
			}
		} else {
			ferret->statistics.fcs_bad++;
			if (ferret->cfg.interface_checkfcs) {
				frame->flags.found.bad_fcs = 1;
				return;
			}
		}
	}

	switch (frame->layer2_protocol) {
	case 1: /* Ethernet */
		process_ethernet_frame(ferret, frame, px, length);
		break;
	case 0x69: /* WiFi */
		process_wifi_frame(ferret, frame, px, length);
		break;
	case 119: /* DLT_PRISM_HEADER */
		/* This was original created to handle Prism II cards, but now we see this
		 * from other cards as well, such as the 'madwifi' drivers using Atheros
		 * chipsets.
		 *
		 * This starts with a "TLV" format, a 4-byte little-endian tag, followed by
		 * a 4-byte little-endian length. This TLV should contain the entire Prism
		 * header, after which we'll find the real header. Therefore, we should just
		 * be able to parse the 'length', and skip that many bytes. I'm told it's more
		 * complicated than that, but it seems to work right now, so I'm keeping it 
		 * this way.
		 */
		if (length < 8) {
			FRAMERR(frame, "unknown linktype = %d (expected Ethernet or wifi)\n", frame->layer2_protocol);
			return;
		}
		if (ex32le(px+0) != 0x00000044) {
			FRAMERR(frame, "unknown linktype = %d (expected Ethernet or wifi)\n", frame->layer2_protocol);
			return;
		} else {
			unsigned header_length = ex32le(px+4);

			if (header_length >= length) {
				FRAMERR(frame, "unknown linktype = %d (expected Ethernet or wifi)\n", frame->layer2_protocol);
				return;
			}

			/*
			 * Ok, we've skipped the Prism header, now let's process the 
			 * wifi packet as we would in any other case. TODO: in the future,
			 * we should parse the Prism header and extract some of the
			 * fields, such as signal strength.
			 */
			process_wifi_frame(ferret, frame, px+header_length, length-header_length);
		}
		break;

	case 127: /* Radiotap headers */
		if (length < 4) {
			//FRAMERR(frame, "radiotap headers too short\n");
			return;
		}
		{
			unsigned version = px[0];
			unsigned header_length = ex16le(px+2);
			unsigned features = ex32le(px+4);

			if (version != 0 || header_length > length) {
				FRAMERR(frame, "radiotap headers corrupt\n");
				return;
			}

			/* If FCS is present at the end of the packet, then change
			 * the length to remove it */
			if (features & 0x4000) {
				unsigned fcs_header = ex32le(px+header_length-4);
				unsigned fcs_frame = ex32le(px+length-4);
				if (fcs_header == fcs_frame)
					length -= 4;
				if (header_length >= length) {
					FRAMERR(frame, "radiotap headers corrupt\n");
					return;
				}
			}

			process_wifi_frame(ferret, frame, px+header_length, length-header_length);

		}
		break;
	default:
		FRAMERR(frame, "unknown linktype = %d (expected Ethernet or wifi)\n", frame->layer2_protocol);
		break;
	}
}
