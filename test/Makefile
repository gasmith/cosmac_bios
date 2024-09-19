TARGETS := eeprom rx stack tx

%.bin: %.asm
	asm02 -b $<

all: $(TARGETS:=.bin)

test: $(TARGETS:=_test)

clean:
	rm -f *.bin *.build *.prg

%_test: %.bin
	./run.sh -i $<

.PHONY: all clean
