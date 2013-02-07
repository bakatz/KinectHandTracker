#!/bin/bash -e

if [ "`uname -s`" == "Darwin" ]; then
        LIBEXT="dylib"
else
        LIBEXT="so"
fi

cp Bin/libXnVNite*$LIBEXT /usr/lib
cp Bin/libXnVCNITE*$LIBEXT /usr/lib
cp Bin/libXnVNITE.jni*$LIBEXT /usr/lib
if [ -e Makefile ]
then
	mkdir -p /usr/include/nite
	cp Include/* /usr/include/nite
fi
cp Bin/com.primesense.NITE.jar /usr/share/java/

for fdir in `ls -1 | grep Features`
do
	mkdir -p /usr/etc/primesense/$fdir
	cp $fdir/Data/* /usr/etc/primesense/$fdir
	for so in `ls -1 $fdir/Bin/lib*$LIBEXT`
	do
		base=`basename $so`
		cp $so /usr/lib
		niReg /usr/lib/$base /usr/etc/primesense/$fdir
	done
done
for hdir in `ls -1 | grep Hands`
do
	mkdir -p /usr/etc/primesense/$hdir
	cp $hdir/Data/* /usr/etc/primesense/$hdir
	for so in `ls -1 $hdir/Bin/lib*$LIBEXT`
	do
		base=`basename $so`
		cp $so /usr/lib
		niReg /usr/lib/$base /usr/etc/primesense/$hdir
	done
done

if [ -f /usr/bin/gmcs ]
then
	for net in `ls -1 Bin/*dll`
	do
		gacutil -i $net -package 2.0
		netdll=`basename $net`
		echo $netdll >> /usr/etc/primesense/XnVNITE.net.dll.list
	done
fi

LIC_KEY=""
ASK_LIC="1"
while (( "$#" )); do
	case "$1" in
	-l=*)
		ASK_LIC="0"
		LIC_KEY=${1:3}
		;;
	esac
	shift
done

if [ "$ASK_LIC" == "1" ]; then
	printf "Please enter your PrimeSense license key: "
	read LIC_KEY
fi

if [ -z "$LIC_KEY" ]; then
	echo
	echo "*** WARNING: *****************************************************"
	echo "** No license key provided. Note that you can always install    **"
	echo "** new license keys by running:                                 **"
	echo "**                                                              **"
	echo "**    niLicense PrimeSense <key>                                **"
	echo "**                                                              **"
	echo "******************************************************************"
else
        niLicense PrimeSense $LIC_KEY
fi

if [ -e Makefile ]
then
	make
fi
