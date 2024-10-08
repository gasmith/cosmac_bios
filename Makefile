TARGETS := bios blinkenlights loader minimon

all: $(TARGETS:=.bin) stage1.bin

clean:
	rm -f *.bin *.build *.prg

.PHONY: all clean

%.bin: %.asm inc/*.asm
	asm02 -b $<

%.cksum: %.bin
	./cksum.py $< -o $@

bios-stamped.bin: bios.bin bios.cksum
	cp bios.bin $@
	truncate -s -2 $@
	cat bios.cksum >> $@

stage1-head.bin: stage1-head.asm loader.asm inc/*.asm
	asm02 -b $<

stage1.bin: stage1-head.bin bios-stamped.bin
	cp stage1-head.bin $@
	dd if=bios-stamped.bin of=stage1.bin bs=256 oseek=6
