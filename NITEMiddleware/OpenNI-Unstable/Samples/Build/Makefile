include Common/CommonDefs.mak

.PHONY: all

NETPROJ = 
ifneq "$(realpath /usr/bin/gmcs)" ""
	NETPROJ += SimpleRead.net
	NETPROJ += SimpleViewer.net
	NETPROJ += UserTracker.net
endif

all: $(NETPROJ) NiAudioSample NiBackRecorder NiConvertXToONI NiCRead NiHandTracker NiRecordSynthetic NiSampleModule NiSimpleCreate NiSimpleRead NiSimpleSkeleton NiSimpleViewer NiUserSelection NiUserTracker NiViewer SimpleRead.java SimpleViewer.java UserTracker.java 


.PHONY: NiAudioSample
NiAudioSample:
	$(MAKE) -C ../NiAudioSample

.PHONY: NiBackRecorder
NiBackRecorder:
	$(MAKE) -C ../NiBackRecorder

.PHONY: NiConvertXToONI
NiConvertXToONI:
	$(MAKE) -C ../NiConvertXToONI

.PHONY: NiCRead
NiCRead:
	$(MAKE) -C ../NiCRead

.PHONY: NiHandTracker
NiHandTracker:
	$(MAKE) -C ../NiHandTracker

.PHONY: NiRecordSynthetic
NiRecordSynthetic:
	$(MAKE) -C ../NiRecordSynthetic

.PHONY: NiSampleModule
NiSampleModule:
	$(MAKE) -C ../NiSampleModule

.PHONY: NiSimpleCreate
NiSimpleCreate:
	$(MAKE) -C ../NiSimpleCreate

.PHONY: NiSimpleRead
NiSimpleRead:
	$(MAKE) -C ../NiSimpleRead

.PHONY: NiSimpleSkeleton
NiSimpleSkeleton:
	$(MAKE) -C ../NiSimpleSkeleton

.PHONY: NiSimpleViewer
NiSimpleViewer:
	$(MAKE) -C ../NiSimpleViewer

.PHONY: NiUserSelection
NiUserSelection:
	$(MAKE) -C ../NiUserSelection

.PHONY: NiUserTracker
NiUserTracker:
	$(MAKE) -C ../NiUserTracker

.PHONY: NiViewer
NiViewer:
	$(MAKE) -C ../NiViewer

.PHONY: SimpleRead.java
SimpleRead.java:
	$(MAKE) -C ../SimpleRead.java

.PHONY: SimpleRead.net
SimpleRead.net:
	$(MAKE) -C ../SimpleRead.net

.PHONY: SimpleViewer.java
SimpleViewer.java:
	$(MAKE) -C ../SimpleViewer.java

.PHONY: SimpleViewer.net
SimpleViewer.net:
	$(MAKE) -C ../SimpleViewer.net

.PHONY: UserTracker.java
UserTracker.java:
	$(MAKE) -C ../UserTracker.java

.PHONY: UserTracker.net
UserTracker.net:
	$(MAKE) -C ../UserTracker.net
