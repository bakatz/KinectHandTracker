include Common/CommonDefs.mak

.PHONY: all

NETPROJ = 
ifneq "$(realpath /usr/bin/gmcs)" ""
	NETPROJ += Boxes.net
endif

all: $(NETPROJ) Boxes Boxes.java CircleControl Players PointServer PointViewer SceneAnalysis SingleControl TrackPad 


.PHONY: Boxes
Boxes:
	$(MAKE) -C ../Boxes -f Boxes.mak

.PHONY: Boxes.java
Boxes.java:
	$(MAKE) -C ../Boxes.java -f Boxes.java.mak

.PHONY: Boxes.net
Boxes.net:
	$(MAKE) -C ../Boxes.net -f Boxes.net.mak

.PHONY: CircleControl
CircleControl:
	$(MAKE) -C ../CircleControl -f CircleControl.mak

.PHONY: Players
Players:
	$(MAKE) -C ../Players -f Players.mak

.PHONY: PointServer
PointServer:
	$(MAKE) -C ../PointServer -f PointServer.mak

.PHONY: PointViewer
PointViewer:
	$(MAKE) -C ../PointViewer -f PointViewer.mak

.PHONY: SceneAnalysis
SceneAnalysis:
	$(MAKE) -C ../SceneAnalysis -f SceneAnalysis.mak

.PHONY: SingleControl
SingleControl:
	$(MAKE) -C ../SingleControl -f SingleControl.mak

.PHONY: TrackPad
TrackPad:
	$(MAKE) -C ../TrackPad -f TrackPad.mak
