PKG      := package
TYPE     := Plasma/Applet
ID       := $(shell python3 -c "import json;print(json.load(open('$(PKG)/metadata.json'))['KPlugin']['Id'])")
VERSION  := $(shell python3 -c "import json;print(json.load(open('$(PKG)/metadata.json'))['KPlugin']['Version'])")
QMLFILES := $(shell find $(PKG) -name '*.qml')
# Use the Qt 6 linter explicitly: on some distros /usr/bin/qmllint is the Qt 5 one.
QMLLINT  ?= $(firstword $(wildcard /usr/lib/qt6/bin/qmllint /usr/lib/x86_64-linux-gnu/qt6/bin/qmllint /usr/lib64/qt6/bin/qmllint) qmllint)

.PHONY: help install upgrade uninstall check lint view window preview config-preview widget-preview popup-test restart-shell archive verify-install

help:
	@echo "Targets: install upgrade uninstall check lint verify-install view window preview config-preview widget-preview popup-test restart-shell archive"
	@echo "Plugin id: $(ID)  version: $(VERSION)"

install:
	kpackagetool6 -t $(TYPE) -i $(PKG)

upgrade:
	kpackagetool6 -t $(TYPE) -u $(PKG)

uninstall:
	kpackagetool6 -t $(TYPE) -r $(ID)

# Structural checks on metadata.json (required keys, semver version).
check:
	@python3 -c "import json,re,sys; d=json.load(open('$(PKG)/metadata.json')); k=d['KPlugin']; \
	assert d.get('KPackageStructure')=='Plasma/Applet', 'KPackageStructure must be Plasma/Applet'; \
	[k[x] for x in ('Id','Name','Version','License')]; \
	assert re.fullmatch(r'\d+\.\d+\.\d+', k['Version']), 'Version must be semver'; \
	assert d.get('X-Plasma-API-Minimum-Version'), 'X-Plasma-API-Minimum-Version missing'; \
	print('metadata ok:', k['Id'], k['Version'])"
	@test -f $(PKG)/contents/ui/main.qml
	@test -f $(PKG)/contents/config/main.xml
	@python3 -c "import xml.dom.minidom; xml.dom.minidom.parse('$(PKG)/contents/config/main.xml'); print('main.xml well-formed')"

# i18n() is injected at runtime by KLocalizedContext, so every call trips the
# "unqualified" check; demote that category to info and treat the rest as errors.
lint:
	$(QMLLINT) -I /usr/lib/qt6/qml --unqualified info --missing-property error --Quick.layout-positioning error --unused-imports warning $(QMLFILES)

# Installs into a throwaway XDG_DATA_HOME to prove kpackagetool6 accepts the package.
verify-install:
	@tmp=$$(mktemp -d) && \
	XDG_DATA_HOME=$$tmp QT_QPA_PLATFORM=offscreen kpackagetool6 -t $(TYPE) -i $(PKG) && \
	test -f $$tmp/plasma/plasmoids/$(ID)/metadata.json && \
	echo "package installs ok" && rm -rf $$tmp

# Requires plasma-sdk (plasmoidviewer). Use --formfactor horizontal|vertical|planar to test panels.
view:
	plasmoidviewer -a $(PKG) $(ARGS)

# Renders the *installed* widget's full view to build/preview.png without a
# focus change: runs plasmawindowed as an X11 (XWayland) client and grabs its
# window with ImageMagick. Set PREVIEW_WAIT to sample more history first.
PREVIEW_WAIT ?= 8
preview:
	@mkdir -p build
	@QT_QPA_PLATFORM=xcb plasmawindowed $(ID) >build/preview.log 2>&1 & \
	sleep $(PREVIEW_WAIT); \
	wid=$$(xdotool search --name '$(shell python3 -c "import json;print(json.load(open('$(PKG)/metadata.json'))['KPlugin']['Name'])")' | head -1); \
	if [ -n "$$wid" ]; then import -window $$wid build/preview.png && echo "wrote build/preview.png"; else echo "widget window not found (see build/preview.log)"; fi; \
	pkill -x plasmawindowed || true

# Opens/closes the popup of the panel instance via a temporary global shortcut.
popup-test:
	tools/toggle-popup.sh $(ARGS)

# Renders the settings page (from the source tree, not the installed copy)
# to build/config-preview.png using the plain qml runtime.
config-preview:
	@mkdir -p build
	@QT_QPA_PLATFORM=xcb qml6 -I /usr/lib/qt6/qml tools/ConfigHarness.qml >build/config-preview.log 2>&1 & pid=$$!; \
	sleep 6; \
	wid=$$(xdotool search --name ConfigHarness | head -1); \
	if [ -n "$$wid" ]; then import -window $$wid build/config-preview.png && echo "wrote build/config-preview.png"; else echo "harness window not found (see build/config-preview.log)"; fi; \
	kill $$pid 2>/dev/null || true

# Renders panel views at several heights/styles, a vertical panel, the full
# view and the no-GPU states (from the source tree) to build/widget-preview.png.
widget-preview:
	@mkdir -p build
	@QT_QPA_PLATFORM=xcb qml6 -I /usr/lib/qt6/qml tools/WidgetHarness.qml >build/widget-preview.log 2>&1 & pid=$$!; \
	sleep 8; \
	wid=$$(xdotool search --name WidgetHarness | head -1); \
	if [ -n "$$wid" ]; then import -window $$wid build/widget-preview.png && echo "wrote build/widget-preview.png"; else echo "harness window not found (see build/widget-preview.log)"; fi; \
	kill $$pid 2>/dev/null || true

restart-shell:
	@if systemctl --user is-active --quiet plasma-plasmashell.service; then \
		systemctl --user restart plasma-plasmashell.service; \
	else \
		kquitapp6 plasmashell || true; kstart plasmashell >/dev/null 2>&1 & \
	fi

archive:
	rm -f $(ID)-$(VERSION).plasmoid
	cd $(PKG) && zip -r ../$(ID)-$(VERSION).plasmoid . -x '*~'
	@echo "Built $(ID)-$(VERSION).plasmoid"

# Runs the *installed* widget in a standalone window (part of plasma-workspace, no SDK needed).
window:
	plasmawindowed $(ID)
