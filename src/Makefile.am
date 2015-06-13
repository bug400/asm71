all-local:	
	fpc asm71.pas

install-exec-local:
	$(MKDIR_P) "$(DESTDIR)$(bindir)" 
	$(LIBTOOL) $(AM_LIBTOOLFLAGS) $(LIBTOOLFLAGS) --mode=install $(INSTALL_PROGRAM) asm71 $(DESTDIR)$(bindir)

clean-local:
	rm -f asm71$(EXEEXT)
	rm -f asm71.$(OBJEXT)
	
