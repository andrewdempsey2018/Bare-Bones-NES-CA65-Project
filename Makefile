begin_build:	
	echo " DEBUG build start ->"
	ca65 src/main.asm -g -o main.o
	ld65 -o output.nes -C ld65.cfg main.o --dbgfile output.dbg
	ld65 -C ld65.cfg -o output.nes main.o --mapfile output.map
	echo "------- DEBUG build S-U-C-C-E-S-S.-------"