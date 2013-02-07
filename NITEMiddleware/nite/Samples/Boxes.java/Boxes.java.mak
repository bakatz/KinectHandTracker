BIN_DIR = ../Bin

SRC_FILES = \
        com/primesense/NITE/Samples/Boxes/*.java

JAR_NAME = com.primesense.NITE.Samples.Boxes
USED_JARS = com.primesense.NITE org.OpenNI
MAIN_CLASS = com.primesense.NITE.Samples.Boxes.BoxesApplication

include ../Build/Common/CommonJavaMakefile

