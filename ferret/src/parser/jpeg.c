/* Copyright (c) 2007 by Errata Security, All Rights Reserved
 * Programer(s): Robert David Graham [rdg]
 */
#include "parser.h"
#include "ferret.h"
#include "netframe.h"
#include "formats.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>

#include "module/md5rfc1321.h"

void parse_jpeg_ichat_image(struct Ferret *ferret, struct NetFrame *frame, const unsigned char *px, unsigned length)
{
	MD5_CTX context;
	unsigned char digest[16];

	UNUSEDPARM(frame);UNUSEDPARM(ferret);

	MD5Init(&context);
	MD5Update(&context, px, length);
	MD5Final(digest, &context);

	/*TODO: we should do something with this image */
}


