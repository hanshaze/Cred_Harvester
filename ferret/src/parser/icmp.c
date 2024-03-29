/* Copyright (c) 2007 by Errata Security, All Rights Reserved
 * Programer(s): Robert David Graham [rdg]
 */
/*
	INTERNET CONTROL MESSAGE PROTOCOL
*/
#include "parser.h"
#include "ferret.h"
#include "netframe.h"
#include "formats.h"


void process_icmp(struct Ferret *ferret, struct NetFrame *frame, const unsigned char *px, unsigned length)
{
	unsigned type = px[0];
	unsigned code = px[1];
	unsigned checksum = ex16be(px+2);

	UNUSEDPARM(length);UNUSEDPARM(frame);UNUSEDPARM(checksum);

	ferret->statistics.icmp++;

	JOTDOWN(ferret, 
		JOT_SZ("TEST","icmp"),
		JOT_NUM("type",type),
		JOT_NUM("code",code),
		0);
}

void process_icmpv6(struct Ferret *ferret, struct NetFrame *frame, const unsigned char *px, unsigned length)
{
	unsigned type = px[0];
	unsigned code = px[1];
	unsigned checksum = ex16be(px+2);

	UNUSEDPARM(length);UNUSEDPARM(frame);UNUSEDPARM(checksum);
	JOTDOWN(ferret, 
		JOT_SZ("TEST","icmp"),
		JOT_NUM("type",type),
		JOT_NUM("code",code),
		0);

	if (frame->dst_ipv6[0] == 0xFF)
	JOTDOWN(ferret, 
		JOT_MACADDR("ID-MAC", frame->src_mac),
		JOT_IPv6("ipv6", frame->src_ipv6, 16),
		0);
}


