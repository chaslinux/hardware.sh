#!/bin/bash -efu
######################################################################
# What WiFi technology(ies) does this Linux machine have?
# Written by "Nosey" Nick for / (C)opyright 2026 CR @ TWC
# All wrong righted. All rights reserved.
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

###    TECH GEN 802.xx # notes
# ++++++++++ Test / add 8 / 9 here?
iwgrep  UHR  8 "11bn, or greater" # UNTESTED 
iwgrep  EHT  7  11be   # UNTESTED - "Extremely High Throughput" - WiFi 7
#            6e 11ax   ? 6E adds 6GHz channels?
iwgrep  HE   6  11ax   # UNTESTED "High Efficiency" - WiFi 6
iwgrep  VHT  5  11ac   #   TESTED "Very High Throughput" implies WiFi 5
iwgrep  HT   4  11n    #   TESTED "High Throughput" indicating WiFi 4
#            3  11g    # grep for what?
#            2g 11a    # grep for what?
#            2  11b    # grep for what?
#            1  11     # grep for what?

echo "ERR: Does this even have a WiFi card?!? Check: iw phy" >&2
exit 1
