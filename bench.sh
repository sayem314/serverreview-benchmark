#!/bin/bash
# serverreview-benchmark by @sayem314
# Github: https://github.com/sayem314/serverreview-benchmark

about () {
	echo ""
	echo "  ========================================================= "
	echo "  \             Serverreview Benchmark Script             / "
	echo "  \       Basic system info, I/O test and speedtest       / "
	echo "  \                V 2.3.0  (14 Dec 2017)                   / "
	echo "  \             Created by Sayem Chowdhury                / "
	echo "  ========================================================= "
	echo ""
	echo "  This script is based on bench.sh by camarg from akamaras.com"
	echo "  Later it was modified by dmmcintyre3 on FreeVPS.us"
	echo "  Thanks to Hidden_Refuge for the update of this script"
	echo ""
}

prms () {
	echo "  $(tput setaf 3)-info$(tput sgr0)          - Check basic system information"
	echo "  $(tput setaf 3)-io$(tput sgr0)            - Run I/O test with or w/ cache"
	echo "  $(tput setaf 3)-cdn$(tput sgr0)           - Check download speed from CDN"
	echo "  $(tput setaf 3)-northamercia$(tput sgr0)  - Download speed from North America"
	echo "  $(tput setaf 3)-europe$(tput sgr0)        - Download speed from Europe"
	echo "  $(tput setaf 3)-asia$(tput sgr0)          - Download speed from asia"
	echo "  $(tput setaf 3)-a$(tput sgr0)             - Test and check all above things at once"
	echo "  $(tput setaf 3)-b$(tput sgr0)             - System info, CDN speedtest and I/O test"
	echo "  $(tput setaf 3)-ispeed$(tput sgr0)        - Install speedtest-cli (python 2.4-3.4 required)"
	echo "  $(tput setaf 3)-speed$(tput sgr0)         - Check internet speed using speedtest-cli"
	echo "  $(tput setaf 3)-about$(tput sgr0)         - Check about this script"
	echo ""
}

howto () {
	echo ""
	echo "  Wrong parameters. Use $(tput setaf 3)bash bench -help$(tput sgr0) to see parameters"
	echo "  ex: $(tput setaf 3)bash bench -info$(tput sgr0) (without quotes) for system information"
	echo ""
}

systeminfo () {
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

	# Systeminfo
	echo ""
	echo " $(tput setaf 6)## System Information$(tput sgr0)"
	echo ""

	# OS Information (Name)
	if [ "$cpubits" == 'x86_64' ]; then
		bits=" (64 bit)"
	else
		bits=" (32 bit)"
	fi

	if hash lsb_release 2>/dev/null; then
		soalt=$(lsb_release -d)
		echo -e " OS Name:    "${soalt:13} $bits
	else
		so=$(cat /etc/issue)
		pos=$(expr index "$so" 123456789)
		so=${so/\/}
		extra=""
		if [[ "$so" == Debian*6* ]]; then
			extra="(squeeze)"
		fi
		if [[ "$so" == Debian*7* ]]; then
			extra="(wheezy)"
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
		echo -e " OS Name:    "${so:0:($pos+2)} $extra$bits
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
	elif [ "$eth" == *eth0* ];then
		virtual="Dedicated"
	elif [[ -e /proc/xen ]]; then
		virtual="Xen"
	fi

	#Kernel
	echo " Kernel:     $virtual / $(uname -r)"
	sleep 0.1

	# Hostname
	echo " Hostname:   $(hostname)"
	sleep 0.1

	# CPU Model Name
	echo " CPU Model: $cpumodel"
	sleep 0.1

	# Cpu Cores
	if [[ $cores == "1" ]]; then
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
	if [[ "$tswap0" == "0kB" ]]; then
		echo " Total SWAP: SWAP not enabled"
	else
		echo " Total SWAP: $tswap (Free $fswap)"
	fi
	sleep 0.1
	echo " Total Space: $hdd ($hddfree used)"
	sleep 0.1

	# Uptime
	secs=$( awk '{print $1}' /proc/uptime | cut -f1 -d"." )
	if [[ $secs -lt 120 ]]; then
		sysuptime="$secs seconds"
	elif [[ $secs -lt 3600 ]]; then
		sysuptime=$( printf '%d minutes %d seconds\n' $(($secs%3600/60)) $(($secs%60)) )
	elif [[ $secs -lt 86400 ]]; then
			sysuptime=$( printf '%dhrs %dmin %dsec\n' $(($secs/3600)) $(($secs%3600/60)) $(($secs%60)) )
	else
		sysuptime=$( echo $((secs/86400))"days - "$(date -d "1970-01-01 + $secs seconds" "+%Hhrs %Mmin %Ssec") )
	fi
	echo " Running for: $sysuptime"
	echo ""
}

cdnspeedtest () {
	echo ""
	echo " $(tput setaf 6)## CDN Speedtest$(tput sgr0)"
	cachefly=$( wget -O /dev/null http://cachefly.cachefly.net/100mb.test 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " CacheFly:  $cachefly"

	gdrive=$( wget -O /dev/null "https://doc-00-48-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/8gcbhohheb8c39lr2aafdrsdushc6q1e/1513245600000/01596048466545378513/*/1EcDdTYwJNBIXx_BL6pzEkjTD_pkCbYni?e=download" 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " Gdrive:  $gdrive"
	echo ""
}

northamerciaspeedtest () {
	echo ""
	echo " $(tput setaf 6)## North America Speedtest$(tput sgr0)"
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
	echo ""
	echo " $(tput setaf 6)## Europe Speedtest$(tput sgr0)"
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
	echo ""
	echo " $(tput setaf 6)## Asia Speedtest$(tput sgr0)"
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
	echo ""
	echo " $(tput setaf 6)## IO Test$(tput sgr0)"
	io=$( ( dd if=/dev/zero of=test bs=64k count=16k conv=fdatasync && rm -f test ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
	echo " I/O Speed : $io"
	
	io=$( ( dd if=/dev/zero of=test bs=64k count=16k conv=fdatasync oflag=direct && rm -f test ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
	echo " I/O Direct : $io"
	echo ""
}

installspeedtest () {
	# Installing speed test
	wget -q --no-check-certificate https://raw.github.com/sivel/speedtest-cli/master/speedtest_cli.py
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
