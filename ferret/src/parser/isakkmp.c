/* Copyright (c) 2007 by Errata Security, All Rights Reserved
 * Programer(s): Robert David Graham [rdg]
 */
/*
	ISAKMP

  This protocol is used for encrypted VPN connections. When
  the user sets up a connection, we can grab information from
  the private keys to figure out what company they work for.

  TODO: this is just a place holder right now.

*/
#include "parser.h"
#include "netframe.h"
#include "ferret.h"
#include "formats.h"
#include <string.h>


void process_isakmp(struct Ferret *ferret, struct NetFrame *frame, const unsigned char *px, unsigned length)
{
	unsigned type;

	return; /*TODO: add code later */
	if (length < 1) {
		FRAMERR_TRUNCATED(frame, "isakmp");
		return;
	}

	type = px[0];
	SAMPLE(ferret,"ISAKMP", JOT_NUM("type", type));

	switch (type) {
	case 0xFF: /* keep alive */
		break;
	default:
		FRAMERR_UNKNOWN_UNSIGNED(frame, "isakmp", type);
		break;
	}
}

