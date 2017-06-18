# Makefile -- generate docset
#
# Require https://github.com/pyenv/pyenv
#

SHELL = /bin/bash -l

# Default target
.PHONY: default
default: all

# Check that pyenv is available
PYENV = $(shell command -v pyenv)

ifeq ($(PYENV),)
  $(error [error] You MUST install pyenv first (see https://github.com/pyenv/pyenv))
endif

# Some useful variables
empty :=
space := $(empty) $(empty)

# Debug (D=1) and Verbose (V=1)
ifeq ($(D),1)
  Q = @echo$(space)
else
  ifeq ($(V),1)
    Q =
  else
    Q = @
  endif
endif

# --------------------------------------------------------------------------------------------------------------------
# Variables

# Versions
BITBAKE_VERSION = 2.3
PY27 = 2.7.13

# Sources
BITBAKE_SRC_URL  = https://www.yoctoproject.org/docs/$(BITBAKE_VERSION)/bitbake-user-manual
BITBAKE_DEST_DIR = bitbake.docset/Contents/Resources/Documents

BITBAKE_SRC_HTML = $(BITBAKE_DEST_DIR)/bitbake-user-manual.html
BITBAKE_SRC_CSS  = $(BITBAKE_DEST_DIR)/bitbake-user-manual-style.css

BITBAKE_SRC_FILES = $(BITBAKE_SRC_HTML) $(BITBAKE_SRC_CSS)

BITBAKE_DOCSET_DB = bitbake.docset/Contents/Resources/docSet.dsidx

DOCSETS = bitbake.docset.tgz

# --------------------------------------------------------------------------------------------------------------------
# Rules

$(PYENV_ROOT)/versions/%/bin/activate:
	@echo "ACTIVATE VIRTUALENV: yd-$(PY27)"
	$(Q)pyenv virtualenv $(PY27) $*

.python-version: $(PYENV_ROOT)/versions/yd-$(PY27)/bin/activate .FORCE
	@echo "CREATE VIRTUALENV: yd-$(PY27)"
	$(Q)pyenv local yd-$(PY27)
	$(Q)pyenv rehash

.pyenv-requirements: .python-version
	@echo "INSTALL REQUIREMENTS"
	$(Q)pip install -Ur requirements.txt
	$(Q)touch $@

$(BITBAKE_DEST_DIR)/%:
	@echo "GET HTML SOURCES"
	$(Q)curl -s -o $@ $(BITBAKE_SRC_URL)/$(@F)

$(BITBAKE_DOCSET_DB): $(BITBAKE_SRC_FILES) .pyenv-requirements
	@echo "GENERATE DOCSET DB"
	$(Q)./bitbake-doc2docset.py

%.docset.tgz: %.docset/Contents/Resources/docSet.dsidx
	@echo "GENERATE $@"
	$(Q)tar --exclude='.DS_Store' -cvzf $@ $<

# --------------------------------------------------------------------------------------------------------------------
# Targets

.PHONY: all
all: $(DOCSETS)

.PHONY: clean
clean:
	@echo "CLEAN"
	$(Q)rm -f $(BITBAKE_SRC_FILES) $(BITBAKE_DOCSET_DB) $(DOCSETS)

.PHONY: distclean
distclean: clean
	@echo "DISTCLEAN"
	$(Q)pyenv uninstall yd-$(PY27)
	$(Q)rm -f .pyenv-requirements .python-version

.PHONY: setup
setup: .pyenv-requirements

.PHONY: rebuild
rebuild: distclean all

.FORCE:
