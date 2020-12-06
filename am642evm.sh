#!/bin/bash

# Use Directly from Docker hub if not provided:
IMG_NAME="${IMG_NAME:-nishanthmenon/openocd}"
EVM=am642evm
EVM_GUESS_REGEX="^43"

# Check if docker exists
docker=`which docker`
if [ -z "$docker" ]; then
	echo "Please install Docker and Image nishanthmenon/openocd from:" `dirname $0`
	exit 1
fi

# If we are working off docker image from docker hub, make sure
# we have the latest.
if [ "$IMG_NAME" = "nishanthmenon/openocd" ]; then
	docker pull $IMG_NAME
fi

XDS110_VID_PID="0451:bef3"
# Find the serial number of the xds110 connected to j7200
iserial=`docker run -it --rm --privileged -v /dev/bus/usb:/dev/bus/usb  --entrypoint /usr/bin/lsusb "$IMG_NAME" -vd"$XDS110_VID_PID" |grep iSerial|sed -e 's/\s\s*/|/g'|cut -d '|' -f4 | xargs echo`

if [ -z "$iserial" ]; then
	echo "Please connect $EVM to USB. I cannot find any xds110 on the PC" 1>&2
	exit 1
fi
num_xds110=`echo $iserial|wc -w`
CMD_LINE_SERIAL="$*"
if [ $num_xds110 -gt 1 -a -z "$CMD_LINE_SERIAL" ]; then
	maybe=`echo $iserial|tr ' ' '\n'|grep "$EVM_GUESS_REGEX"`
	if [ -n "$maybe" ]; then
		MAYBE=`echo " Serial number for $EVM might be: $maybe"`
		EX="\nFor example: $0 $maybe"
	fi
	iserials=`echo "$iserial"|tr ' ' ','`
	echo "Oops.. we found $num_xds110 xds110s in your PC. Serial numbers are: $iserials.$MAYBE" 1>&2
	echo -e "You can run $0 <serial_number> $EX" 1>&2
	exit 1
fi
if [ $num_xds110 -gt 1 -a -n "$CMD_LINE_SERIAL" ]; then
	inlist=`echo $iserial|grep -w "$CMD_LINE_SERIAL"`
	if [ -z "$inlist" ]; then
		iserials=`echo "$iserial"|tr ' ' ','`
		echo "Oops! $CMD_LINE_SERIAL is not one of the xds110 serial number $iserials. Please try again with a valid serial number."
		exit 1
	fi
	iserial=$CMD_LINE_SERIAL
fi
echo  "Connecting to $EVM xds110 serial number '$iserial'"
docker run -it --rm --network host --privileged -v /dev/bus/usb:/dev/bus/usb -v `pwd`:/data  "$IMG_NAME" -f board/ti_$EVM.cfg -c 'cmsis_dap_serial "'$iserial'"'
