Ferret 2.0

Intro

Ferret is a tool for sniffing and analyzing packets and pulling out 
"interesting" information. It's like 'tcpdump' in some ways, but it 
doesn't print a decode per packet. Instead, it only outputs when it 
has something interesting to show. This might be several lines of 
text for a single packet, and nothing for thousands more packets.

It's also used with "Hamster" to sniff HTTP session cookies 
(--hamster command-line switch).


Building

The projects/makefiles are in the "ferret/build" directory. For Linux, 
you probably want the "ferret/build/gcc4" directory.

Building is pretty straightforward. If you want to make your own project, 
you can simply compile all the files together. Any errors that occur 
should be obvious how to fix.

Reading the code

The document "read-code.txt" should help you read the code. The way it
parse network packets is different than the way you were taught to in
school (your professors were wrong, the way Ferret does it is correct).

Changes

I'm currently rearranging how the code works, things might be in odd
places at the moment.

See also

See http://ferret.erratasec.com for more information.

Robert Graham
March 9, 2009

