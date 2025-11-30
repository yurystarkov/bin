PREFIX ?= /usr/local
UNAME := $(shell uname -s | tr 'A-Z' 'a-z')

install:
	install -g 755 day                    $(DESTDIR)$(PREFIX)/bin/day
	install -g 755 pass                   $(DESTDIR)$(PREFIX)/bin/pas
	install -g 755 _                      $(DESTDIR)$(PREFIX)/bin/_
	install -g 755 colcol                 $(DESTDIR)$(PREFIX)/bin/colcol
	install -g 755 gurlp                  $(DESTDIR)$(PREFIX)/bin/gurlp
	install -g 755 mks                    $(DESTDIR)$(PREFIX)/bin/mks
	install -g 755 mp3                    $(DESTDIR)$(PREFIX)/bin/mp3
	install -g 755 mkclip                 $(DESTDIR)$(PREFIX)/bin/mkclip
	install -g 755 pasta                  $(DESTDIR)$(PREFIX)/bin/pasta
	install -g 755 pasta                  $(DESTDIR)$(PREFIX)/bin/pasta
	install -g 755 $(UNAME)/ram           $(DESTDIR)$(PREFIX)/bin/ram
	install -g 755 $(UNAME)/ut            $(DESTDIR)$(PREFIX)/bin/ut
	install -g 755 $(UNAME)/ss            $(DESTDIR)$(PREFIX)/bin/ram
	install -g 755 $(UNAME)/epub_pkg2file $(DESTDIR)$(PREFIX)/bin/epub_pkg2file
