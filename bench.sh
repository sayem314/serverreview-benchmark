#!/bin/bash
# serverreview-benchmark by @sayem314
# Github: https://github.com/sayem314/serverreview-benchmark

# shellcheck disable=SC1117,SC2086,SC2003,SC1001,SC2116,SC2046,2128,2124

about () {
	echo ""
	echo "  ========================================================= "
	echo "  \             Serverreview Benchmark Script             / "
	echo "  \       Basic system info, I/O test and speedtest       / "
	echo "  \               V 3.0.0  (xx xxx xxxx)                  / "
	echo "  \             Created by Sayem Chowdhury                / "
	echo "  ========================================================= "
	echo ""
	echo "  This script is based on bench.sh by camarg from akamaras.com"
	echo "  Later it was modified by dmmcintyre3 on FreeVPS.us"
	echo "  Thanks to Hidden_Refuge for the update of this script"
	echo ""
}

prms () {
	echo "  Arguments:"
	echo "    $(tput setaf 3)-info$(tput sgr0)         - Check basic system information"
	echo "    $(tput setaf 3)-io$(tput sgr0)           - Run I/O test with or w/ cache"
	echo "    $(tput setaf 3)-cdn$(tput sgr0)          - Check download speed from CDN"
	echo "    $(tput setaf 3)-northamercia$(tput sgr0) - Download speed from North America"
	echo "    $(tput setaf 3)-europe$(tput sgr0)       - Download speed from Europe"
	echo "    $(tput setaf 3)-asia$(tput sgr0)         - Download speed from asia"
	echo "    $(tput setaf 3)-a$(tput sgr0)            - Test and check all above things at once"
	echo "    $(tput setaf 3)-b$(tput sgr0)            - System info, CDN speedtest and I/O test"
	echo "    $(tput setaf 3)-ispeed$(tput sgr0)       - Install speedtest-cli (python 2.4-3.4 required)"
	echo "    $(tput setaf 3)-speed$(tput sgr0)        - Check internet speed using speedtest-cli"
	echo "    $(tput setaf 3)-about$(tput sgr0)        - Check about this script"
	echo ""
	echo "  Parameters"
	echo "    $(tput setaf 3)share$(tput sgr0)         - upload results (default to hastebin)"
	echo "    $(tput setaf 3)ubuntu$(tput sgr0)        - upload results to ubuntu paste"
}

howto () {
	echo ""
	echo "  Wrong parameters. Use $(tput setaf 3)bash $BASH_SOURCE -help$(tput sgr0) to see parameters"
	echo "  ex: $(tput setaf 3)bash $BASH_SOURCE -info$(tput sgr0) (without quotes) for system information"
	echo ""
}

log="$HOME/bench.log"
ARG="$BASH_SOURCE $@"
benchram="/mnt/tmpbenchram"
true > $log

cancel () {
	echo ""
	rm -f test
	echo " Abort"
	if [[ -d $benchram ]]; then
		rm $benchram/zero
		umount $benchram
		rm -rf $benchram
	fi
	exit
}

trap cancel SIGINT

systeminfo () {
	cpubits=$( uname -m )
	hdd=$( df -h --total | grep 'total' | awk '{print $2}' )B
	hddfree=$( df -h --total | grep 'total' | awk '{print $5}' )
	fswap=$( free -m | grep Swap | awk 'NR=1 {print $4}' )MiB

	# Systeminfo
	echo "" | tee -a $log
	echo " $(tput setaf 6)## System Information$(tput sgr0)"
	echo " ## System Information" >> $log
	echo "" | tee -a $log

	# OS Information (Name)
	if [ "$cpubits" == 'x86_64' ]; then
		bits=" (64 bit)"
	else
		bits=" (32 bit)"
	fi

	if hash lsb_release 2>/dev/null; then
		soalt=$(lsb_release -d)
		echo -e " OS Name     : "${soalt:13} $bits | tee -a $log
	else
		so=$(awk 'NF' /etc/issue)
		pos=$(expr index "$so" 123456789)
		so=${so/\/}
		extra=""
		if [[ "$so" == Debian*9* ]]; then
			extra="(stretch)"
		elif [[ "$so" == Debian*8* ]]; then
			extra="(jessie)"
		elif [[ "$so" == Debian*7* ]]; then
			extra="(wheezy)"
		elif [[ "$so" == Debian*6* ]]; then
			extra="(squeeze)"
		fi
		if [[ "$so" == *Proxmox* ]]; then
			so="Debian 7.6 (wheezy)";
		fi
		otro=$(expr index "$so" \S)
		if [[ "$otro" == 2 ]]; then
			so=$(cat /etc/*-release)
			pos=$(expr index "$so" NAME)
			pos=$((pos-2))
			so=${so/\/}
		fi
		echo -e " OS Name     : "${so:0:($pos+2)}$extra$bits | tr -d '\n' | tee -a $log
		echo "" | tee -a $log
	fi
	sleep 0.1

	#Detect virtualization
	if hash ifconfig 2>/dev/null; then
		eth=$(ifconfig)
	fi
	virtualx=$(dmesg)
	if [[ -f /proc/user_beancounters ]]; then
		virtual="OpenVZ"
	elif [[ "$virtualx" == *kvm-clock* ]]; then
		virtual="KVM"
	elif [[ "$virtualx" == *"VMware Virtual Platform"* ]]; then
		virtual="VMware"
	elif [[ "$virtualx" == *"Parallels Software International"* ]]; then
		virtual="Parallels"
	elif [[ "$virtualx" == *VirtualBox* ]]; then
		virtual="VirtualBox"
	elif [[ "$eth" == *eth0* ]];then
		virtual="Dedicated"
	elif [[ -e /proc/xen ]]; then
		virtual="Xen"
	fi

	#Kernel
	echo " Kernel      : $virtual / $(uname -r)" | tee -a $log
	sleep 0.1

	# Hostname
	echo " Hostname    : $(hostname)" | tee -a $log
	sleep 0.1

	# CPU Model Name
	cpumodel=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo )
	echo " CPU Model   :$cpumodel" | tee -a $log
	sleep 0.1

	# CPU Cores
	cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
	corescache=$( awk -F: '/cache size/ {cache=$2} END {print cache}' /proc/cpuinfo )
	freq=$( awk -F: ' /cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo )
	if [[ $cores == "1" ]]; then
		echo " CPU Cores   : $cores core @ $freq MHz" | tee -a $log
	else
		echo " CPU Cores   : $cores cores @ $freq MHz" | tee -a $log
	fi
	sleep 0.1
	echo " CPU Cache   :$corescache" | tee -a $log
	sleep 0.1

	# RAM Information
	tram="$( free -m | grep Mem | awk 'NR=1 {print $2}' ) MiB"
	fram="$( free -m | grep Mem | awk 'NR=1 {print $4}' ) MiB"
	echo " Total RAM   : $tram (Free $fram)" | tee -a $log
	sleep 0.1

	# Swap Information
	tswap="$( free -m | grep Swap | awk 'NR=1 {print $2}' ) MiB"
	tswap0=$( grep SwapTotal < /proc/meminfo | awk 'NR=1 {print $2$3}' )
	if [[ "$tswap0" == "0kB" ]]; then
		echo " Total SWAP  : SWAP not enabled" | tee -a $log
	else
		echo " Total SWAP  : $tswap (Free $fswap)" | tee -a $log
	fi
	sleep 0.1
	echo " Total Space : $hdd ($hddfree used)" | tee -a $log
	sleep 0.1

	# Uptime
	secs=$( awk '{print $1}' /proc/uptime | cut -f1 -d"." )
	if [[ $secs -lt 120 ]]; then
		sysuptime="$secs seconds"
	elif [[ $secs -lt 3600 ]]; then
		sysuptime=$( printf '%d minutes %d seconds\n' $((secs%3600/60)) $((secs%60)) )
	elif [[ $secs -lt 86400 ]]; then
		sysuptime=$( printf '%dhrs %dmin %dsec\n' $((secs/3600)) $((secs%3600/60)) $((secs%60)) )
	else
		sysuptime=$( echo $((secs/86400))"days - "$(date -d "1970-01-01 + $secs seconds" "+%Hhrs %Mmin %Ssec") )
	fi
	echo " Running for : $sysuptime" | tee -a $log
	echo "" | tee -a $log
}

echostyle(){
	if hash tput 2>/dev/null; then
		echo " $(tput setaf 6)$1$(tput sgr0)"
		echo " $1" >> $log
	else
		echo " $1" | tee -a $log
	fi
}

human_readable() {
	bytes=${1%.*}
	if [[ $bytes -lt 1024 ]]; then
		printf "%4i       B\n"  $1
	else
		postfixes=(KiB MiB GiB TiB EiB PiB YiB ZiB)
		count=0
		while [[ $bytes -ge 1048576 ]]; do
			bytes=$((bytes / 1024))
			count=$((count + 1))
		done
		printf "%4i.%03i %s\n" $((bytes / 1024)) $(((bytes % 1024) * 1000 / 1024)) ${postfixes[$count]}
	fi
}

# main function for speed checking
# the report speed are average per file
speed() {
	# print name
	printf "%s" " $1" | tee -a $log

	# ping one time
	ping_link=$( echo ${2#*//} | cut -d"/" -f1 )
	ping_ms=$( ping -c1 $ping_link | grep 'rtt' | cut -d"/" -f5 )ms

	# get download speed and print
	cdl=$( curl -m 5 -w '%{speed_download}\n' -o /dev/null -s "$2" )
	printf "%s\n" "$(human_readable $cdl)/s (ping $ping_ms)" | tee -a $log
}

# 3 location (300MB)
cdnspeedtest () {
	echo "" | tee -a $log
	echostyle "## CDN Speedtest"
	echo "" | tee -a $log
	speed "CacheFly :" "http://cachefly.cachefly.net/100mb.test"
	speed "CDN.net  :" "http://993660212.r.worldcdn.net/100MB.bin"

	# google drive speed test
	TMP_COOKIES="/tmp/cookies.txt"
	TMP_FILE="/tmp/gdrive"
	DRIVE="drive.google.com"
	FILE_ID="1EcDdTYwJNBIXx_BL6pzEkjTD_pkCbYni"

	printf " Gdrive   :"  | tee -a $log
	curl -c $TMP_COOKIES -o $TMP_FILE -s "https://$DRIVE/uc?id=$FILE_ID&export=download"
	D_ID=$( grep "confirm=" < $TMP_FILE | awk -F "confirm=" '{ print $NF }' | awk -F "&amp" '{ print $1 }' )
	cdl=$( curl -m 5 -Lb $TMP_COOKIES -w '%{speed_download}\n' -o /dev/null \
		-s "https://$DRIVE/uc?export=download&confirm=$D_ID&id=$FILE_ID" )
	printf "%s\n" "$(human_readable $cdl)/s (ping $( ping -c1 $DRIVE | grep 'rtt' | cut -d"/" -f5 )ms)" | tee -a $log
	echo "" | tee -a $log
}

# 10 location (1GB)
northamerciaspeedtest () {
	echo "" | tee -a $log
	echostyle "## North America Speedtest"
	echo "" | tee -a $log
	speed "Softlayer, Washington, USA :" "http://speedtest.wdc01.softlayer.com/downloads/test100.zip"
	speed "SoftLayer, San Jose, USA   :" "http://speedtest.sjc01.softlayer.com/downloads/test100.zip"
	speed "SoftLayer, Dallas, USA     :" "http://speedtest.dal01.softlayer.com/downloads/test100.zip"
	speed "Vultr, New Jersey, USA     :" "http://nj-us-ping.vultr.com/vultr.com.100MB.bin"
	speed "Vultr, Seattle, USA        :" "http://wa-us-ping.vultr.com/vultr.com.100MB.bin"
	speed "Vultr, Dallas, USA         :" "http://tx-us-ping.vultr.com/vultr.com.100MB.bin"
	speed "Vultr, Los Angeles, USA    :" "https://lax-ca-us-ping.vultr.com/vultr.com.100MB.bin"
	speed "Ramnode, New York, USA     :" "http://lg.nyc.ramnode.com/static/100MB.test"
	speed "Ramnode, Atlanta, USA      :" "http://lg.atl.ramnode.com/static/100MB.test"
	speed "OVH, Beauharnois, Canada   :" "http://bhs.proof.ovh.net/files/100Mio.dat"
	echo ""
}

# 9 location (900MB)
europespeedtest () {
	echo "" | tee -a $log
	echostyle "## Europe Speedtest"
	echo "" | tee -a $log
	speed "Vultr, London, UK            :" "http://lon-gb-ping.vultr.com/vultr.com.100MB.bin"
	speed "LeaseWeb, Frankfurt, Germany :" "http://mirror.de.leaseweb.net/speedtest/100mb.bin"
	speed "Hetzner, Germany             :" "https://speed.hetzner.de/100MB.bin"
	speed "Ramnode, Alblasserdam, NL    :" "http://lg.nl.ramnode.com/static/100MB.test"
	speed "Vultr, Amsterdam, NL         :" "http://ams-nl-ping.vultr.com/vultr.com.100MB.bin"
	speed "EDIS, Stockholm, Sweden      :" "http://se.edis.at/100MB.test"
	speed "OVH, Roubaix, France         :" "http://rbx.proof.ovh.net/files/100Mio.dat"
	speed "Online, France               :" "http://ping.online.net/100Mo.dat"
	speed "Prometeus, Milan, Italy      :" "http://mirrors.prometeus.net/test/test100.bin"
	echo "" | tee -a $log
}

# 4 location (200MB)
pacificpeedtest () {
	echo "" | tee -a $log
	echostyle "## Pacific Speedtest"
	echo "" | tee -a $log
	speed "Sydney, Australia     :" "https://syd-au-ping.vultr.com/vultr.com.100MB.bin"
	speed "Lagoon, New Caledonia :" "http://mirror.lagoon.nc/speedtestfiles/test50M.bin"
	speed "Hosteasy, Moldova     :" "http://mirror.as43289.net/speedtest/100mb.bin"
	speed "Prima, Argentina      :" "http://sftp.fibertel.com.ar/services/file-50MB.img"
	echo "" | tee -a $log
}

# 4 location (400MB)
asiaspeedtest () {
	echo "" | tee -a $log
	echostyle "## Asia Speedtest"
	echo "" | tee -a $log
	speed "SoftLayer, Singapore :" "http://speedtest.sng01.softlayer.com/downloads/test100.zip"
	speed "Linode, Tokyo, Japan :" "http://speedtest.tokyo.linode.com/100MB-tokyo.bin"
	speed "Linode, Singapore    :" "http://speedtest.singapore.linode.com/100MB-singapore.bin"
	speed "Vultr, Tokyo, Japan  :" "http://hnd-jp-ping.vultr.com/vultr.com.100MB.bin"
	echo "" | tee -a $log
}

freedisk() {
	# check free space
	freespace=$( df -m . | awk 'NR==2 {print $4}' )
	if [[ $freespace -ge 1024 ]]; then
		printf "%s" $((1024*2))
	elif [[ $freespace -ge 512 ]]; then
		printf "%s" $((512*2))
	elif [[ $freespace -ge 256 ]]; then
		printf "%s" $((256*2))
	elif [[ $freespace -ge 128 ]]; then
		printf "%s" $((128*2))
	else
		printf 1
	fi
}

averageio() {
	ioraw1=$( echo $1 | awk 'NR==1 {print $1}' )
		[ "$(echo $1 | awk 'NR==1 {print $2}')" == "GB/s" ] && ioraw1=$( awk 'BEGIN{print '$ioraw1' * 1024}' )
	ioraw2=$( echo $2 | awk 'NR==1 {print $1}' )
		[ "$(echo $2 | awk 'NR==1 {print $2}')" == "GB/s" ] && ioraw2=$( awk 'BEGIN{print '$ioraw2' * 1024}' )
	ioraw3=$( echo $3 | awk 'NR==1 {print $1}' )
		[ "$(echo $3 | awk 'NR==1 {print $2}')" == "GB/s" ] && ioraw3=$( awk 'BEGIN{print '$ioraw3' * 1024}' )
	ioall=$( awk 'BEGIN{print '$ioraw1' + '$ioraw2' + '$ioraw3'}' )
	ioavg=$( awk 'BEGIN{printf "%.1f", '$ioall' / 3}' )
	printf "%s" "$ioavg"
}

iotest () {
	echo "" | tee -a $log
	echostyle "## IO Test"
	echo "" | tee -a $log

	# start testing
	writemb=$(freedisk)

	# CPU Speed test
	echo " CPU Speed:" | tee -a $log
	io=$( ( dd bs=512K count=$writemb if=/dev/zero of=test; rm -f test ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
	echo "   md5sum -$io" | tee -a $log
	echo "" | tee -a $log

	# Disk test
	echo " Disk Speed:" | tee -a $log
	if [[ $writemb != "1" ]]; then
		io=$( ( dd bs=512K count=$writemb if=/dev/zero of=test; rm -f test ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
		echo "   I/O Speed  -$io" | tee -a $log

		io=$( ( dd bs=512K count=$writemb if=/dev/zero of=test oflag=dsync; rm -f test ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
		echo "   I/O Direct -$io" | tee -a $log
	else
		echo "   Not enough space to test." | tee -a $log
	fi
	echo "" | tee -a $log

	# RAM Speed test
	# set ram allocation for mount
	tram_mb="$( free -m | grep Mem | awk 'NR=1 {print $2}' )"
	if [[ tram_mb -gt 1900 ]]; then
		sbram=1024
	else
		sbram=$(( tram_mb / 2 ))M
	fi
	[[ -d $benchram ]] || mkdir $benchram
	mount -t tmpfs -o size=$sbram tmpfs $benchram/
	echo " RAM Speed:" | tee -a $log
	iow1=$( ( dd if=/dev/zero of=$benchram/zero bs=512k count=512 ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
	ior1=$( ( dd if=$benchram/zero of=/dev/null bs=512K count=512; rm -f test ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
	iow2=$( ( dd if=/dev/zero of=$benchram/zero bs=512k count=512 ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
	ior2=$( ( dd if=$benchram/zero of=/dev/null bs=512K count=512; rm -f test ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
	iow3=$( ( dd if=/dev/zero of=$benchram/zero bs=512k count=512 ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
	ior3=$( ( dd if=$benchram/zero of=/dev/null bs=512K count=512; rm -f test ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
	echo "   Avg. write - $(averageio "$iow1" "$iow2" "$iow3") MB/s" | tee -a $log
	echo "   Avg. read  - $(averageio "$ior1" "$ior2" "$ior3") MB/s" | tee -a $log
	rm $benchram/zero
	umount $benchram
	rm -rf $benchram
	echo "" | tee -a $log
}

installspeedtest () {
	# Installing speed test
	curl -s https://raw.github.com/sivel/speedtest-cli/master/speedtest_cli.py -o speedtest_cli.py
	chmod a+rx speedtest_cli.py
	mv speedtest_cli.py /usr/local/bin/speedtest-cli
	chown root:root /usr/local/bin/speedtest-cli
	echo " Installing speedtest-cli script has been finished"
	echo " speedtest-cli works with Python 2.4-3.4"
	echo " Run 'bash bench -speed' to run speedtest" | sed $'s/bash bench -speed/\e[1m&\e[0m/'
	echo ""
}

speedtestresults () {
	#Testing Speedtest
	speedtest-cli --share
	echo ""
}

startedon() {
	echo "\$ $ARG" >> $log
	echo "" | tee -a $log
	benchstart=$(date +"%d-%b-%Y %H:%M:%S")
	start_seconds=$(date +%s)
	echo " Benchmark started on $benchstart" | tee -a $log
}

finishedon() {
	end_seconds=$(date +%s)
	echo " Benchmark finished in $((end_seconds-start_seconds)) seconds" | tee -a $log
	echo "   results saved on $log"
	echo "" | tee -a $log
}

sharetest() {
	case $1 in
	'haste' )
		share_link=$( curl -X POST -s -d "$(cat $log)" https://hastebin.com/documents | awk -F '"' '{print "https://hastebin.com/"$4}' );;
	*)
		share_link=$( curl -v --data-urlencode "content@$log" -d "poster=bench.log" -d "syntax=text" "https://paste.ubuntu.com" 2>&1 | \
			grep "Location" | awk '{print $3}' );;
	esac
	echo " Share result:"
	echo " $share_link"
	echo ""

}

case $1 in
	'-info'|'-information'|'--info'|'--information' )
		systeminfo;;
	'-io'|'-drivespeed'|'--io'|'--drivespeed' )
		iotest;;
	'-northamercia'|'-na'|'--northamercia'|'--na' )
		northamerciaspeedtest;;
	'-europe'|'-eu'|'--europe'|'--eu' )
		europespeedtest;;
	'-pacific'|'--pacific' )
		pacificpeedtest;;
	'-asia'|'--asia' )
		asiaspeedtest;;
	'-cdn'|'--cdn' )
		cdnspeedtest;;
	'-b'|'--b' )
		startedon; systeminfo; cdnspeedtest; iotest; finishedon;;
	'-a'|'-all'|'-bench'|'--a'|'--all'|'--bench' )
		startedon; systeminfo; cdnspeedtest; northamerciaspeedtest;
		europespeedtest; pacificpeedtest; asiaspeedtest; iotest; finishedon;;
	'-ispeed'|'-installspeed'|'-installspeedtest'|'--ispeed'|'--installspeed'|'--installspeedtest' )
		installspeedtest;;
	'-speed'|'-speedtest'|'-speedcheck'|'--speed'|'--speedtest'|'--speedcheck' )
		speedtestresults;;
	'-help'|'--help' )
		prms;;
	'-about'|'--about' )
		about;;
	*)
		howto;;
esac

case $2 in
	'-share'|'--share'|'share' )
		sharetest haste;;
	'-haste'|'--haste'|'haste' )
		sharetest haste;;
	'-ubuntu'|'--ubuntu'|'ubuntu' )
		sharetest ubuntu;;
esac

# ring a bell
printf '\007'
