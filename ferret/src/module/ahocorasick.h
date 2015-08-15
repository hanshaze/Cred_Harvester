/* Copyright (c) 2007 by Errata Security, All Rights Reserved
 * Programer(s): Robert David Graham [rdg]
 */
#ifndef __AHOCORASICK_H
#define __AHOCORASICK_H
#ifdef __cplusplus
extern "C" {
#endif


struct ACENGINE;

/**
 * Call this function to search a block of text with the current state.
 *
 * This is meant to be called on byte-streams. Each stream has it's own
 * 'state' variable. As more data arrives on a stream, this function
 * is called to continue searching that new block of data with the 
 * left-over state from the previous call on that stream. This state
 * represents the fact that we may be in the middle of a partial
 * pattern-match. The 'state' is initialized to zero on the first call
 * for a stream, and then saved between calls. Other than a starting
 * value of '0', the value is opaque to the caller.
 *
 * The return value will be '0' if a pattern hasn't been found. The
 * return value will be the 'id' field from 'ac_add_pattern(.., id, ..)
 * when patterns are found.
 */
unsigned ac_search(struct ACENGINE *ac, unsigned *r_state, const unsigned char *px, unsigned length, unsigned *r_offset);


/**
 * After all the patterns have been added, call this function to 
 * compile them into a state machine. Bad things will happen if you
 * attempt to search without having first compiled.
 */
void ac_compile(struct ACENGINE *ac);


/**
 * Adds a binary pattern to the system. If the 'pattern_length' is
 * set to -1, then we assume it's a nul-terminated text string.
 * 
 * The 'id' field should be the unique identifier for this pattern
 * that will be returned whenever a pattern is found. DO NOT USE AN
 * ID OF ZERO '0'!!!
 *
 * As of the current version, pattern matching is case sensitive.
 */
void ac_add_pattern(struct ACENGINE *ac, unsigned id, const void *pattern_text, int pattern_length);


/**
 * Creates an engine that you can add patterns to, compile, then 
 * do searches on. Use 'ac_destroy()" to clean up after yourself.
 */
struct ACENGINE *ac_create();

/**
 * Cleans up an object allocated by 'ac_create()'
 */
void ac_destroy(struct ACENGINE *ac)



#ifdef __cplusplus
}
#endif
#endif /*__AHOCORASICK_H*/
