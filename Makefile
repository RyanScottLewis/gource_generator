SRCDIR        = src
BINDIR        = bin
BUILDDIR      = build

SOURCE        = ~/Bookmarks/Software

GENERATE_CR   = $(SRCDIR)/generate.cr
GENERATE_EXE  = $(BINDIR)/generate
GENERATE_DATA = $(BUILDDIR)/data

CLEAN         = $(BUILDDIR) $(BINDIR)
BUILDS        = 

RM            = rm -rf
MKDIR         = mkdir -p $(@D)
CRYSTAL       = crystal build -o $@ $<
GOURCE        = gource $< --camera-mode track --max-file-lag 0.1 --seconds-per-day 0.05 --disable-bloom
GENERATE      = $(GENERATE_EXE) $(SOURCE) $(GENERATE_DATA)

view: $(GENERATE_DATA)
	$(GOURCE)

build: $(GENERATE_EXE)

data: $(GENERATE_DATA)

clean:
	$(RM) $(CLEAN)

$(GENERATE_DATA): $(GENERATE_EXE)
	@$(MKDIR)
	$(GENERATE)

$(GENERATE_EXE): $(GENERATE_CR)
	@$(MKDIR)
	$(CRYSTAL)

