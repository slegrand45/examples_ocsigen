copy:
	cp -f shared/* 00200-static-table/src/mysite/
	cp -f shared/* 00300-url-param/src/mysite/
	cp -f shared/* 00400-add-product/src/mysite/

all: copy
	(cd 00100-hello-world/src/mysite/ && $(MAKE))
	(cd 00200-static-table/src/mysite/ && $(MAKE))
	(cd 00300-url-param/src/mysite/  && $(MAKE))
	(cd 00400-add-product/src/mysite/  && $(MAKE))

distclean:
	(cd 00100-hello-world/src/mysite/ && $(MAKE) distclean)
	(cd 00200-static-table/src/mysite/ && $(MAKE) distclean)
	(cd 00300-url-param/src/mysite/  && $(MAKE) distclean)
	(cd 00400-add-product/src/mysite/  && $(MAKE) distclean)
