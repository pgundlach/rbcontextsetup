TRANG=/usr/bin/trang.jar

all: interface.rnc

%.rnc: %.rng
	java -jar $(TRANG)  -I rng -O rnc $< $@  

