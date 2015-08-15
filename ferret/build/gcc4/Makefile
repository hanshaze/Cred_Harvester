# This will point to the root of the FERRET project
SRCDIR = ../../src
DSTDIR = ../../bin
TMPDIR = ../../tmp

LIBS = -ldl -lpcap
INCLUDES = -I. -I$(SRCDIR) -I$(SRCDIR)/include -DSTATICPCAP

CC = gcc
CFLAGS = -g $(INCLUDES) -Wall

.SUFFIXES: .c .cpp


$(TMPDIR)/%.o: $(SRCDIR)/main/%.c
	$(CC) $(CFLAGS) -c $< -o $@

$(TMPDIR)/%.o: $(SRCDIR)/module/%.c
	$(CC) $(CFLAGS) -c $< -o $@

$(TMPDIR)/%.o: $(SRCDIR)/parser/%.c
	$(CC) $(CFLAGS) -c $< -o $@

$(TMPDIR)/%.o: $(SRCDIR)/netstack/%.c
	$(CC) $(CFLAGS) -c $< -o $@

$(TMPDIR)/%.o: $(SRCDIR)/crypto/%.c
	$(CC) $(CFLAGS) -c $< -o $@



main_sources := $(wildcard $(SRCDIR)/main/*.c)
module_sources := $(wildcard $(SRCDIR)/module/*.c)
parser_sources := $(wildcard $(SRCDIR)/parser/*.c)
netstack_sources := $(wildcard $(SRCDIR)/netstack/*.c)
crypto_sources := $(wildcard $(SRCDIR)/crypto/*.c)

SRC = $(main_sources) $(module_sources) $(parser_sources) $(netstack_sources) $(crypto_sources)

OBJ = $(addprefix $(TMPDIR)/, $(notdir $(addsuffix .o, $(basename $(SRC))))) $(TMPDIR)/main.o

$(DSTDIR)/ferret: $(OBJ)
	$(CC) $(CFLAGS) -o $@ $(OBJ) -lm $(LIBS) -lstdc++

depend:
	makedepend $(CFLAGS) -Y $(SRC)

clean:
	rm -f $(OBJ)

$(TMPDIR)/main.o: $(SRCDIR)/main/main.cpp
	$(CC) $(CFLAGS) -c $< -o $@
