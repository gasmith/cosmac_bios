TARGETS := atoi eeprom rx rx16 stack tx

%.bin: %.asm
	asm02 -b $<

all: $(TARGETS:=.bin)

test: $(TARGETS:=_test)

clean:
	rm -f *.bin *.build *.prg *-output.evlog

%_test: %.bin
	./run.sh -i $<

.PHONY: all clean
