#!/bin/bash
about () {
	echo ""
	echo "  ========================================================= "
	echo "  \             Serverreview Benchmark Script             / "
	echo "  \       Basic system info, I/O test and speedtest       / "
	echo "  \                V 2.2.2  (24 Mar 2015)                   / "
	echo "  \             Created by Sayem Chowdhury                / "
	echo "  ========================================================= "
	echo ""
	echo "  This script is based on bench.sh by camarg from akamaras.com"
	echo "  Later it was modified by dmmcintyre3 on FreeVPS.us"
	echo "  Thanks to Hidden_Refuge for the update of this script"
	echo ""
}
prms () {
	echo "  -info          - Check basic system information" | sed $'s/ -info/\e[1m&\e[0m/'
	echo "  -io            - Run I/O test with or w/ cache" | sed $'s/ -io/\e[1m&\e[0m/'
	echo "  -cdn           - Check download speed from CDN" | sed $'s/ -cdn/\e[1m&\e[0m/'
	echo "  -northamercia  - Download speed from North America" | sed $'s/ -northamercia/\e[1m&\e[0m/'
	echo "  -europe        - Download speed from Europe" | sed $'s/ -europe/\e[1m&\e[0m/'
	echo "  -asia          - Download speed from asia" | sed $'s/ -asia/\e[1m&\e[0m/'
	echo "  -a             - Test and check all above things at once" | sed $'s/ -a/\e[1m&\e[0m/'
	echo "  -b             - System info, CDN speedtest and I/O test" | sed $'s/ -b/\e[1m&\e[0m/'
	echo "  -ispeed        - Install speedtest-cli (python 2.4-3.4 required)" | sed $'s/ -ispeed/\e[1m&\e[0m/'
	echo "  -speed         - Check internet speed using speedtest-cli" | sed $'s/ -speed/\e[1m&\e[0m/'
	echo "  -about         - Check about this script" | sed $'s/ -about/\e[1m&\e[0m/'
	echo ""
}
howto () {
	echo "Wrong parameters. Use 'bash bench -help' to see parameters" | sed $'s/bash bench -help/\e[1m&\e[0m/'
	echo "ex: 'bash bench -info' (without quotes) for system information" | sed $'s/bash bench -info/\e[1m&\e[0m/'
	echo ""
}
systeminfo () {
	hostname=$( hostname )
	cpumodel=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo )
	cpubits=$( uname -m )
	cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
	corescache=$( awk -F: '/cache size/ {cache=$2} END {print cache}' /proc/cpuinfo )
	freq=$( awk -F: ' /cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo )
	tram=$( free -h | grep Mem | awk 'NR=1 {print $2}' )B
	fram=$( free -h | grep Mem | awk 'NR=1 {print $4}' )B
	hdd=$( df -h --total | grep 'total' | awk '{print $2}' )B
	hddfree=$( df -h --total | grep 'total' | awk '{print $5}' )
	tswap=$( free -h | grep Swap | awk 'NR=1 {print $2}' )B
	tswap0=$( cat /proc/meminfo | grep SwapTotal | awk 'NR=1 {print $2$3}' )
	fswap=$( free -h | grep Swap | awk 'NR=1 {print $4}' )B
	uptime=$( awk '{print int($1/86400)"days - "int($1%86400/3600)"hrs "int(($1%3600)/60)"min "int($1%60)"sec"}' /proc/uptime )
	# Systeminfo
	echo ""
	echo " ##System Information" | sed $'s/ ##System Information/\e[93m&\e[0m/'
	echo ""
	# OS Information (Name)
	if [ "$cpubits" == 'x86_64' ]; then
	bits=" (64 bit)"
	else
	bits=" (32 bit)"
	fi
	if hash lsb_release 2>/dev/null; 
	then
	soalt=`lsb_release -d`
	echo -e " OS Name:    "${soalt:13} $bits
	else
	so=`cat /etc/issue`
	pos=`expr index "$so" 123456789`
	so=${so/\/}
	extra=""
	if [[ "$so" == Debian*6* ]]; 
	then
	extra="(squeeze)"
	fi
	if [[ "$so" == Debian*7* ]]; 
	then
	extra="(wheezy)"
	fi
	if [[ "$so" == *Proxmox* ]]; 
	then
	so="Debian 7.6 (wheezy)";
	fi
	otro=`expr index "$so" \S`
	if [[ "$otro" == 2 ]]; 
	then
	so=`cat /etc/*-release`
	pos=`expr index "$so" NAME`
	pos=$((pos-2))
	so=${so/\/}
	fi
	echo -e " OS Name:    "${so:0:($pos+2)} $extra$bits
	fi
	sleep 0.1
	# Hostname
	echo " Hostname:   $hostname"
	sleep 0.1
	# CPU Model Name
	echo " CPU Model: $cpumodel"
	sleep 0.1
	# Cpu Cores
	if [ $cores=1 ]
	then
	echo " CPU Cores:  $cores core @ $freq MHz"
	else
	echo " CPU Cores:  $cores cores @ $freq MHz"
	fi
	sleep 0.1
	echo " CPU Cache: $corescache"
	sleep 0.1
	# Ram Information
	echo " Total RAM:  $tram (Free $fram)"
	sleep 0.1
	# Swap Information
	if [ "$tswap0" = '0kB' ]
	then
	echo " Total SWAP: You do not have SWAP enabled"
	else
	echo " Total SWAP: $tswap (Free $fswap)"
	fi
	sleep 0.1
	echo " Total Space: $hdd ($hddfree used)"
	sleep 0.1
	# Uptime
	echo " Running for: $uptime"
	echo ""
}
cdnspeedtest () {
	echo ""; echo " ##CDN Speedtest" | sed $'s/ ##CDN Speedtest/\e[93m&\e[0m/'
	cachefly=$( wget -O /dev/null http://cachefly.cachefly.net/100mb.test 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' ); echo " CacheFly:  $cachefly"
	internode=$( wget -O /dev/null http://speedcheck.cdn.on.net/100meg.test 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' ); echo " Internode: $internode"
	echo ""
}
northamerciaspeedtest () {
	echo ""; echo " ##North America Speedtest" | sed $'s/ ##North America Speedtest/\e[93m&\e[0m/'
	nas1=$( wget -O /dev/null http://speedtest.dal01.softlayer.com/downloads/test100.zip 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " SoftLayer, Dallas, USA: $nas1"
	nas2=$( wget -O /dev/null http://speedtest.choopa.net/100MBtest.bin 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " ReliableSite, Piscataway, USA: $nas2"
	nas3=$( wget -O /dev/null http://bhs.proof.ovh.net/files/100Mio.dat 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " OVH, Beauharnois, Canada: $nas3"
	nas4=$( wget -O /dev/null http://speedtest.wdc01.softlayer.com/downloads/test100.zip 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " Softlayer, Washington, USA: $nas4"
	nas5=$( wget -O /dev/null http://speedtest.sjc01.softlayer.com/downloads/test100.zip 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " SoftLayer, San Jose, USA: $nas5"
	nas6=$( wget -O /dev/null http://tx-us-ping.vultr.com/vultr.com.100MB.bin 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " Vultr, Dallas, USA: $nas6"
	nas7=$( wget -O /dev/null http://nj-us-ping.vultr.com/vultr.com.100MB.bin 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " Vultr, New Jersey, USA: $nas7"
	nas8=$( wget -O /dev/null http://wa-us-ping.vultr.com/vultr.com.100MB.bin 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " Vultr, Seattle, USA: $nas8"
	echo ""
}
europespeedtest () {
	echo ""; echo " ##Europe Speedtest" | sed $'s/ ##Europe Speedtest/\e[93m&\e[0m/'
	es1=$( wget -O /dev/null http://149.3.140.170/100.log 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " RedStation, Gosport, UK: $es1"
	es2=$( wget -O /dev/null http://se.edis.at/100MB.test 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " EDIS, Stockholm, Sweden: $es2"
	es3=$( wget -O /dev/null http://rbx.proof.ovh.net/files/100Mio.dat 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " OVH, Roubaix, France: $es3"
	es5=$( wget -O /dev/null http://mirrors.prometeus.net/test/test100.bin 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " Prometeus, Milan, Italy: $es5"
	es6=$( wget -O /dev/null http://mirror.de.leaseweb.net/speedtest/100mb.bin 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " LeaseWeb, Frankfurt, Germany: $es6"
	es7=$( wget -O /dev/null http://mirror.i3d.net/100mb.bin 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " Interactive3D, Amsterdam, NL: $es7"
	es8=$( wget -O /dev/null http://lon-gb-ping.vultr.com/vultr.com.100MB.bin 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " Vultr, London, UK: $es8"
	es9=$( wget -O /dev/null http://ams-nl-ping.vultr.com/vultr.com.100MB.bin 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " Vultr, Amsterdam, NL: $es9"
	echo ""
}
asiaspeedtest () {
	echo ""; echo " ##Asia Speedtest" | sed $'s/ ##Asia Speedtest/\e[93m&\e[0m/'
	as1=$( wget -O /dev/null http://speedtest.sng01.softlayer.com/downloads/test100.zip 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " SoftLayer, Singapore, Singapore $as1"
	as2=$( wget -O /dev/null http://speedtest.singapore.linode.com/100MB-singapore.bin 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " Linode, Singapore, Singapore $as2"
	as3=$( wget -O /dev/null http://speedtest.tokyo.linode.com/100MB-tokyo.bin 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " Linode, Tokyo, Japan: $as3"
	as4=$( wget -O /dev/null http://hnd-jp-ping.vultr.com/vultr.com.100MB.bin 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " Vultr, Tokyo, Japan: $as4"
	echo ""
}
iotest () {
	echo ""; echo " ##IO Test" | sed $'s/ ##IO Test/\e[93m&\e[0m/'
	io=$( ( dd if=/dev/zero of=test bs=64k count=16k conv=fdatasync && rm -f test ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
	echo " I/O Speed : $io"
	io=$( ( dd if=/dev/zero of=test bs=64k count=16k conv=fdatasync oflag=direct && rm -f test ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
	echo " I/O Direct : $io"
	echo ""
}
installspeedtest () {
	# Installing speed test
	wget -q --no-check-certificate https://raw.github.com/sivel/speedtest-cli/master/speedtest_cli.py && chmod a+rx speedtest_cli.py && mv speedtest_cli.py /usr/local/bin/speedtest-cli && chown root:root /usr/local/bin/speedtest-cli
	echo " Installing speedtest-cli script has been finished"
	echo " speedtest-cli works with Python 2.4-3.4"
	echo " You do not need to run this second time"
	echo " Run 'bash bench -speed' to run speedtest" | sed $'s/bash bench -speed/\e[1m&\e[0m/'
	echo ""
}
speedtestresults () {
	#Testing Speedtest
	speedtest-cli --share
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
	'-asia'|'--asia' )
		asiaspeedtest;;
	'-cdn'|'--cdn' )
		cdnspeedtest;;
	'-b'|'--b' )
		systeminfo; cdnspeedtest; iotest;;
	'-a'|'-all'|'-bench'|'--a'|'--all'|'--bench' )
		systeminfo; cdnspeedtest; northamerciaspeedtest; europespeedtest; asiaspeedtest; iotest;;
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
