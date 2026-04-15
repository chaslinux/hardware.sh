#!/bin/bash -efu
######################################################################
# What WiFi technology/generation does this Linux machine support?
# Written by NoseyNick for / (C)opyright 2026 CR @ TWC
# All wrong righted. All rights reserved.
# Licensed under GPLv3, the General Public License v3.0
######################################################################
# ++++++++++ TODO: Support for MULTIPLE cards by breaking on "Wiphy phy2" lines?

PHY=$(iw phy) # collect PHYsical wifi hardware info

# Function to identify different WiFi technologies by grep  :-/
iwgrep () {
	# Call me with the pattern to grep for,
	#   the implied wifi version,
	#   the 802.[11 / other crap],
	#   and any other grep args
	PAT="$1"  WIFI="$2" ELEVEN="$3"; shift 3
	if grep "$@" "[ 	]$PAT" >&2 <<<"$PHY"; then
		echo "WiFi $WIFI (802.$ELEVEN $PAT)"
		exit 0
	fi
}
echo Scanning for WiFi capabilities... >&2

######################################################################
# Table of different WiFi types, and how to recognise them by using
# the above iwgrep. Ref https://en.wikipedia.org/wiki/IEEE_802.11

###     TECH      GEN 802.xx # notes # ++++++++++ Add + test 9/10/11 here?
iwgrep  UHR        8 "11bn, or greater" # UNTESTED
iwgrep  EHT        7  11be   # UNTESTED - "Extremely High Throughput" - WiFi 7
iwgrep  "6.* MHz"  6e 11ax   # UNTESTED - anything better to grep than freqs?
iwgrep  HE         6  11ax   # UNTESTED "High Efficiency" - WiFi 6
iwgrep  VHT        5  11ac   #   TESTED "Very High Throughput" implies WiFi 5
iwgrep  HT         4  11n    #   TESTED "High Throughput" indicating WiFi 4
iwgrep "54.0 Mbps" 3  11g    # UNTESTED - anything better to grep than speed?
iwgrep  "5.* MHz"  2g 11a    # UNTESTED - anything better to grep than freqs?
iwgrep "11.0 Mbps" 2  11b    # UNTESTED - anything better to grep than speed?
iwgrep  "1.0 Mbps" 1  11     # UNTESTED - anything better to grep than speed?

echo "ERR: Does this even have a WiFi card?!? Check: iw phy" >&2
exit 1
