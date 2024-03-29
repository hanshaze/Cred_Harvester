/* Copyright (c) 2007 by Errata Security, All Rights Reserved
 * Programer(s): Robert David Graham [rdg]
 */
/*
	ETHERNET

  This decodes packets coming from an Ethernet network.

  TODO: we need to support more encapsulations, such as 802.2 SAP
  packets.
*/
#include "parser.h"
#include "formats.h"
#include "netframe.h"
#include "ferret.h"
#include <string.h>
#include <stdio.h>

typedef unsigned char MACADDR[6];


void dispatch_ethertype(struct Ferret *ferret, struct NetFrame *frame, const unsigned char *px, unsigned length, unsigned oui, unsigned ethertype)
{
	SAMPLE(ferret,"SAP", JOT_NUM("oui", oui));
	SAMPLE(ferret,"SAP", JOT_NUM("ethertype", ethertype));

	switch (ethertype) {
	case 0x1083: /* Regress: defcon2008\dump070.pcap(2939) */
	case 0x2b5c: /* Regress: defcon2008\dump113.pcap(89673) */
	case 0x8f08: /* Regress: defcon2008\dump143.pcap(70839) */
	case 0x8c79: /* Regress: defcon2008\dump191.pcap(847) */
	case 0x08cf: /* Regress: defcon2008\dump191.pcap(847) */
	case 0x08a8: /* Regress: defcon2008\dump218.pcap(42163) */
	case 0xf3ba: /* Regress: defcon2008\dump271.pcap(5933) */
		break;
	case 0x0800:
		process_ip(ferret, frame, px, length);
		break;
	case 0x0806:
		process_arp(ferret, frame, px, length);
		break;
	case 0x888e: /*802.11x authentication*/
		process_802_1x_auth(ferret, frame, px, length);
		break;
	case 0x86dd: /* IPv6*/
		process_ipv6(ferret, frame, px, length);
		break;
	case 0x872d: /* Cisco OWL */
		break;
	case 0x9000: /* Loopback */
		break;
	case 0x80f3: /* AARP - Appletalk ARP */
		break;
	case 0x809b: /* Appletalk DDP */
		break;
	default:
		FRAMERR_BADVAL(frame, "ethertype", ethertype);
	}
}

void process_spanningtree_frame(struct Ferret *ferret, struct NetFrame *frame, const unsigned char *px, unsigned length)
{
	/* see parse_PVSTP */
	unsigned offset=0;
	unsigned protocol_identifier;
	unsigned protocol_version;
	unsigned type;

	if (length < 4) {
		FRAMERR_TRUNCATED(frame, "SpanningTree");
		return;
	}

	protocol_identifier = ex16be(px);
	protocol_version = px[2];
	type = px[3];
	
	if (protocol_identifier != 0) {
		FRAMERR(frame, "%s: unknown protocol: 0x%x\n", "SpanningTree", protocol_identifier);
	}
	if (protocol_version != 0) {
		FRAMERR(frame, "%s: unknown version: 0x%x\n", "SpanningTree", protocol_identifier);
	}

	switch (type){
	case 0:
	case 0x80:
		parse_PVSTP(ferret, frame, px, length);
		break;
	default:
		FRAMERR(frame, "%s: unknown type: 0x%x\n", "SpanningTree", type);
		return;
	}
}

void process_snap_frame(struct Ferret *ferret, struct NetFrame *frame, const unsigned char *px, unsigned length)
{
	unsigned offset=0;
	unsigned oui;
	unsigned ethertype;

	if (length < 5) {
		FRAMERR_TRUNCATED(frame, "SNAP");
		return;
	}

	oui = ex24be(px);
	ethertype = ex16be(px+3);

	switch (oui){
	case 0x000000:
		/* fall through below */
		break;
	case 0x004096: /* Cisco Wireless */
		FRAMERR(frame, "Unknown SAP OUI: 0x%06x\n", oui);
		return;
		break;
	case 0x00000c:
		offset +=3; /* skip OUI, pass Ethertype into function */
		process_cisco00000c(ferret, frame, px+offset, length-offset);
		return;
	case 0x080007: /* AppleTalk -- should just process it like any other ethertype */
		break;
	default:
		FRAMERR(frame, "Unknown SAP OUI: 0x%06x\n", oui);
		return;
	}

	dispatch_ethertype(ferret, frame, px+offset, length-offset, oui, ethertype);
}

void process_llc_frame(struct Ferret *ferret, struct NetFrame *frame, const unsigned char *px, unsigned length)
{
	unsigned dsap;
	unsigned ssap;
	unsigned control;
	unsigned offset=0;

	if (length < 3) {
		//FRAMERR_TRUNCATED(frame, "LLC");
		return;
	}

	dsap = px[0];
	ssap = px[1];
	control = px[2];

	if (dsap == 0 && ssap == 0 && control == 0 && memcmp(frame->dst_mac, "\x01\x00\x5e", 3)==0) {
		/* Regress: defcon2008/dump000.pcap(6239) */
		; /* TODO: process_upnp_discovery */
		return;
	}	
	if (dsap == 0 && ssap == 0 && control == 0 && memcmp(frame->dst_mac, "\x33\x33\xff", 3)==0) {
		/* Regress: defcon2008/dump001.pcap(90968) */
		; /* TODO: process_upnp_discovery */
		return;
	}	
	if (dsap == 0 && ssap == 0 && control == 0 && memcmp(frame->dst_mac, "\x33\x33\x00", 3)==0) {
		/* Regress: defcon2008/dump001.pcap(90968) */
		; /* TODO: process_upnp_discovery */
		return;
	}	

	if ((control & 1) == 0) {
		/* This is an "information frame */
		offset += 4;
		if (offset < length) {
			switch (dsap<<8 | ssap) {
			case 0x0000:
				break;
			default:
				FRAMERR_UNPARSED(frame, "LLC:control", control);
				break;
			}
			return;
		}
		return;
	}

	if (control != 0x03) {
		FRAMERR_UNPARSED(frame, "LLC:control", control);
		return;
	}

	offset += 3;

	if (dsap == 0xAA || ssap == 0xAA)
		process_snap_frame(ferret, frame, px+offset, length-offset);
	else if (dsap == 0x42 || ssap == 0x42)
		process_spanningtree_frame(ferret, frame, px+offset, length-offset);
	else {
		FRAMERR_UNPARSED(frame, "LLC:dsap:ssap", ((dsap<<8)|(ssap)));
		return;
	}
}

#if 0
		if (ethertype < 1518) {
			if (memcmp(px+offset, "\xaa\xaa\x03", 3) != 0) {
				JOTDOWN(ferret,
					JOT_SZ("proto","ethernet"),
					JOT_SZ("op","data.unknown"),
					JOT_PRINT("data", 	px+offset,				length-offset),
					0);
				return;
			}
			offset +=3 ;

			oui = ex24be(px+offset);

			/* Look for OUI code */
			switch (oui){
			case 0x000000:
				/* fall through below */
				break;
			case 0x004096: /* Cisco Wireless */
				return;
				break;
			case 0x00000c:
				offset +=3;
				if (offset < length)
				process_cisco00000c(ferret, frame, px+offset, length-offset);
				return;
			case 0x080007:
				break; /*apple*/
			default:
				FRAMERR(frame, "Unknown SAP OUI: 0x%06x\n", oui);
				return;
			}
			offset +=3;

			/* EtherType */
			if (offset+2 >= length) {
				FRAMERR(frame, "ethertype: packet too short\n");
				return;
			}

		}

		if (ethertype == length-offset && ex16be(px+offset) == 0xAAAA) {
			;
		}
		else
#endif

void process_ethernet_frame(struct Ferret *ferret, struct NetFrame *frame, const unsigned char *px, unsigned length)
{
	unsigned offset;
	unsigned ethertype;
	
	if (length <= 14) {
		; /*FRAMERR(frame, "wifi.data: too short\n");*/
		return;
	}

	frame->src_mac = px+6;
	frame->dst_mac = px+0;
	
	offset = 12;


	/* Look for SAP header */
	if (offset + 6 >= length) {
		FRAMERR(frame, "wifi.sap: too short\n");
		return;
	}

	ethertype = ex16be(px+offset);
	offset += 2;

	/* Ethertypes less than 2000 are 802.3 length fields instead, and
	 * are followed by an LLC header */
	if (ethertype < 1518) {
		unsigned new_length = ethertype;

		if (ethertype == 0x0000) {
			/* Regress: defcon2008/dump000.pcap(114689) */
			/* I don't know what this is */
			return;
		}

		px += offset;
		length -= offset;
		if (new_length > length) {
			FRAMERR_BADVAL(frame, "ethertype", ethertype);
			return;
		} else if (new_length < length)
			length = new_length;
		process_llc_frame(ferret, frame, px, length);
		return;
	}

	dispatch_ethertype(ferret, frame, px+offset, length-offset, 0, ethertype);
}
