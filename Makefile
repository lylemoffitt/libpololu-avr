# NOTE: to compile with avr-gcc less than verson 4.2.3, you must
# remove the atmega328p from the list of target devices below:
devices := atmega48 atmega168 atmega328p

.PHONY: all
library_files:
	$(foreach device,$(devices),$(MAKE) -C devices/$(device); )

.PHONY: clean
clean:
	$(foreach device,$(devices),$(MAKE) clean -C devices/$(device); )
	if [ -e examples_templates -a -e examples ]; then \
		for dir in examples/*/*; \
		do \
			$(MAKE) clean -C $$dir; \
		done; \
		rm -rf examples; \
	fi


# set the PREFIX to point to the location of avr-gcc
PREFIX := $(shell which avr-gcc | sed 's/\/bin\/avr-gcc//')/avr
INCLUDE := $(PREFIX)/include
INCLUDE_POLOLU := $(INCLUDE)/pololu
LIB := $(PREFIX)/lib

.PHONY: install
LIBRARY_FILES := $(foreach device,$(devices),libpololu_$(device).a)
install: $(LIBRARY_FILES)
	install -d $(LIB)
	install -d $(INCLUDE_POLOLU)
	install -t $(LIB) $(foreach device,$(devices),libpololu_$(device).a)
	install -t $(INCLUDE_POLOLU) pololu/*.h
	install -t $(INCLUDE_POLOLU) pololu/orangutan

# We make all of the examples from templates in the examples_templates
# directory (which is not distributed), by running a bunch of commands
# concatenated together with &&.

examples_3pi := 3pi-demo-program 3pi-linefollower-pid 3pi-linefollower 3pi-mazesolver 3pi-serial-slave
examples_orangutan := buzzer1 buzzer3 lcd2 pushbuttons1 analog2 buzzer2 lcd1 motors2 simple-test 3pi-serial-master SV-168_demo_program LV-168_demo_program

# The 48 examples are the only ones that will work on the mega48.
# They will also work on the orangutans, which could have either a 168
# or a 328 processor.

examples_atmega48 := analog1 motors1 led1
examples_atmega168 := $(examples_atmega48) $(examples_3pi) $(examples_orangutan)
examples_atmega328p := $(examples_atmega48) $(examples_3pi) $(examples_orangutan)

example_template = examples_templates/$(example)
example_dir = examples/$(device)/$(example)
hex_dir = examples/$(device)/hex_files

make_example = $(foreach example,$(value examples_$(device)), \
		mkdir -p $(example_dir) && \
		cp -a $(example_template)/*.[ch] $(example_dir)/ && \
		cat examples_templates/template_$(device).mk $(example_template)/Makefile > $(example_dir)/Makefile && \
		cat $(example_template)/*.aps | sed 's/<PART>.*<\/PART>/<PART>$(device)<\/PART>/' > $(example_dir)/$(example).aps && \
		)

.PHONY: examples
examples:
	$(foreach device,$(devices),$(make_example)) test 0

make_hex_files = mkdir -p $(hex_dir) && \
	$(foreach example,$(value examples_$(device)), \
	make -C $(example_dir) && \
	cp -a $(example_dir)/*.hex $(hex_dir)/$(example).hex && \
	)

.PHONY: hex_files
hex_files: examples
	$(foreach device,$(devices),$(make_hex_files)) test 0

# The following code creates the zip file.
ZIPDIR=lib_zipfiles
DATE := $(shell date +%y%m%d)
LIB_ZIPFILE := $(ZIPDIR)/libpololu-avr-$(DATE).zip
HEX_ZIPFILE := $(ZIPDIR)/libpololu-avr-example-hex-files-$(DATE).zip
ARDUINO_ZIPFILE := $(ZIPDIR)/PololuArduinoLibraries-$(DATE).zip
ARDUINO_QTR_ZIPFILE := $(ZIPDIR)/PololuQTRSensors-$(DATE).zip

ZIP_EXCLUDES=\*.o .svn/\* \*/.svn/\* \*.hex \*.zip libpololu-avr/arduino_zipfiles/ arduino_zipfiles/\* \*/lib_zipfiles/\* \*.elf \*.eep \*.lss \*.o.d libpololu-avr/libpololu-avr/\* libpololu-avr/extra/\* libpololu-avr/graphics/\* \*.map \*/test/\* \*/ArduinoReadMe.txt \*/examples_templates/\* \*/README-Arduino.txt

ARDUINO_EXCLUDES=libpololu-arduino/OrangutanTime/\* libpololu-arduino/OrangutanSerial/\*

.PHONY: zip
zip: library_files examples hex_files
	rm -f libpololu-avr
	mkdir -p $(ZIPDIR)
	rm -f $(LIB_ZIPFILE)
	rm -f $(ARDUINO_ZIPFILE)
	rm -f $(ARDUINO_QTR_ZIPFILE)
	rm -f $(HEX_ZIPFILE)
	ln -s . libpololu-avr
	zip -rq $(LIB_ZIPFILE) libpololu-avr -x $(ZIP_EXCLUDES)
	zip -rq $(LIB_ZIPFILE) libpololu-avr/examples/*/hex_files/*.hex
	rm libpololu-avr
	#
	ln -s src libpololu-arduino
	zip -rq $(ARDUINO_ZIPFILE) libpololu-arduino -x $(ZIP_EXCLUDES) -x $(ARDUINO_EXCLUDES)
	zip -rq $(ARDUINO_ZIPFILE) libpololu-arduino/README-Arduino.txt
	rm libpololu-arduino
	ln -s src/PololuQTRSensors .
	zip -rq $(ARDUINO_QTR_ZIPFILE) PololuQTRSensors -x $(ZIP_EXCLUDES) -x $(ARDUINO_EXCLUDES)
	rm PololuQTRSensors
