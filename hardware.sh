#!/bin/bash
# Copyright 2022, 2023, 2024, 2025, 2026 Charles McColm, chaslinux@gmail.com
# WiFi updates and tweaks by NoseyNick, wifi-sh@noseynick.net
# Licensed under GPLv3, the General Public License v3.0

# Add some colour to the script
WHITE='\033[1;37m'
NC='\033[0m'
LTGREEN='\033[1;32m'
LTBLUE='\033[1;34m'
PURPLE='\033[1;35m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[1;36m'
REDWHITE='\033[1;37;41m'

# update the system because the script might not work if old software is installed
sudo apt update
echo -e "${LTGREEN}***${CYAN}\e[5m Running updates !  \e[0m${LTGREEN}*** ${NC}"
sudo apt upgrade -y

# Install software for LaTeX, PDF creation, and benchmarking
echo -e "${LTGREEN}*** ${WHITE}Installing Software needed for LaTeX and PDF creation !${LTGREEN}*** ${NC}"
sudo apt -y install \
    lshw \
    mesa-utils \
    smbclient \
    smartmontools \
    libcdio-utils \
    acpi \
    texlive-latex-base \
    texlive-latex-extra \
    barcode \
    texlive-extra-utils \
    texlive-pictures \
    nvme-cli \
    pango1.0-tools sysbench glmark2 imagemagick \
    img2pdf \
    lm-sensors \
    powerstat \
    upower \
    v4l-utils \
    rfkill \
    iw \
    fwupd


# Variables
CURRENTDIR=$(pwd)
DMI=$(sudo dmidecode -t 1) # this has to stay at the top to be used by other variables.
LSB=$(lsb_release -a)
# LHW=$(sudo lshw)
DESKTOP="$HOME/Desktop"
FAMILY=$(echo "$DMI" | grep "Family" | cut -c 10- | tr -d "_")
SERIALNO=$(sudo dmidecode --string system-serial-number)
SLEN=$(echo "$SERIALNO" | awk '{print length}') # added this because SERIAL NUMBER
MMFG=$(echo "$DMI"  | grep Manu | cut -c 16-)
MMODEL=$(echo "$DMI"  | grep Product | cut -c 15- | tr -d "_")
CPUMODEL=$(grep -m 1 "model name" /proc/cpuinfo | cut -c 14-)
COREDETECT=$(sensors | grep "Core ")
AMDTDIE=$(sensors | grep "Tdie:" | cut -c 15-)
VRAM=$(glxinfo | grep "Video memory")
VLEN=$(echo "$VRAM" | awk '{print length}') # vram character length
SDDRIVE=$(ls -1 /dev/sd?)
EMMC=$(ls -l /dev/mmcblk*)
NVME=$(sudo nvme list | grep nvme || true)
NVMENAME=$(sudo nvme list | grep nvme | cut -c -12)
HDDFAMILY=$(sudo smartctl -d ata -a -i "$SDDRIVE" | grep "Model" | tr -d "_")
OSFAMILY=$(echo "$LSB" | grep "Description" | cut -c 14-)
# OSRELEASE=$(lsb_release -a | grep "Release:" | cut -c 10-)
# RAMSIZE=$(sudo lshw -short -class memory | grep "System" | sed 's/^[^m]*memory//' | awk '{$1=$1};1')
TOTALRAM=$(free -g | awk '/^Mem:/ {print $2}') # replace RAMSIZE variable in a future version of the script
# GRAPHICS=$(sudo lshw -C Display | grep product | sed 's/&//g' | cut -c 17-)
PROD1=$(echo "$DMI"  | grep "Manufacturer" | cut -c 16- | tr -d "_")
PROD2=$(echo "$DMI"  | grep "Product Name" | cut -c 16- | tr -d "_")
# PRODUCT="$PROD1 $PROD2"
NETWORK=$(sudo lshw -class network | grep product | cut -c 17-)
echo -e "${LTGREEN}*** ${YELLOW}\e[5mTesting CPU performance, please be patient (approx 15 seconds)...\e[0m ${LTGREEN}*** ${NC}"
SINGLEBENCH=$(sysbench cpu run | grep "events per second:" | cut -c 24-)
MULTIBENCH=$(sysbench --threads="$(nproc)" cpu run | grep "events per second:" | cut -c 24-)
# DEBIANCHECK=$(lsb_release -a | grep "Description" | cut -c 14- | cut -c -6)
BTVERSION=$(hciconfig -a | grep "LMP Version:" | cut -c 15- | cut -c -3)
WIFIVERSION=$(bash -efu "$CURRENTDIR/wifi.sh" 2>/dev/null)
BATPERCENT=$(upower -i $(upower -e | grep BAT) | grep capacity | cut -c 5- | tr -d "%" | cut -c 22-)
BATPERCENT=${BATPERCENT%%.*}
SYSPRODNAME=$(sudo dmidecode -s system-product-name)
BIOSYEAR=$(sudo dmidecode -t bios | grep "Release Date" | grep -oE '[0-9]{4}') # grab the bios year for fwupd


### We found the webcam of the ThinkPad X240 had a red tinge on all apps, this is a workaround
if [[ "$FAMILY" == "ThinkPad X240" ]]; then
	sudo cp "$CURRENTDIR/99-webcam-saturation.rules" /etc/udev/rules.d/.
	sudo udevadm control --reload-rules
	sudo udevadm trigger
fi

# Sony VAIO VPCSB190S has issues with saturation
if [[ "$PROD2" == "VPCSB190S" ]]; then
	sudo cp "$CURRENTDIR/99-webcam-saturation.rules" /etc/udev/rules.d/.
	sudo udevadm control --reload-rules
	sudo udevadm trigger
fi

# MacBook Air 4,2 apparently has saturation issues as well
if [[ "$SYSPRODNAME" == "MacBookAir4,2" ]]; then
	sudo cp "$CURRENTDIR/99-webcam-saturation.rules" /etc/udev/rules.d/.
	sudo udevadm control --reload-rules
	sudo udevadm trigger
fi

if [[ "$TOTALRAM" -le 8 ]]; then
    sudo apt update && sudo apt -y install systemd-zram-generator
    sudo cp "$CURRENTDIR/zram-generator.conf" /etc/systemd
    sudo cp "$CURRENTDIR/99-swappiness.conf" /etc/sysctl.d
fi

###################################################
### This area is for the benchmarks development ###
###################################################

if [ -f "$DESKTOP/sysbench.txt" ]; then
	echo "Removing sysbench.txt..."
	rm "$DESKTOP/sysbench.txt"
else
	echo "No sysbench.txt file, creating one."
fi

if [ -f "$DESKTOP/glmark2.txt" ]; then
	echo "Removing glmark2.txt..."
	rm "$DESKTOP/glmark2.txt"
else
	echo "No glmark2.txt file, creating one."
fi

if [ -f "$DESKTOP/sysbench.png" ]; then
	echo "Removing sysbench.png"
	rm "$DESKTOP/sysbench.png"
fi
if [ -f "$DESKTOP/glmark2.png" ]; then
	echo "Removing glmark2.png"
	rm "$DESKTOP/glmark2.png"
fi

# Create a sysbench text file with the benchmarks
echo -n "CPU (single-core): $SINGLEBENCH CPU (Multi-core): $MULTIBENCH " > "$DESKTOP/sysbench.txt"
# echo "Now running sysbench... be patient for a few seconds..."
# sysbench cpu --cpu-max-prime=10000 run | grep "events per second" | cut -c 25- >> /home/$USER/Desktop/sysbench.txt

# create the glmark2 text file
echo -n "GLMark2: " > "$DESKTOP/glmark2.txt"
echo -e "${LTGREEN}***${PURPLE}\e[5m Now running glmark2... be patient for a few seconds... \e[0m${LTGREEN}***"
glmark2 -b :duration=2.0 -b shading -b build -b :duration-5.0 -b texture | grep "glmark2 Score:" | cut -c 50- >> "$DESKTOP/glmark2.txt"

# Now create the images to be incorporated into the PDF
# pango-view --font="Ubuntu Sans Ultra-Bold" -qo /home/$USER/Desktop/title.png $CURRENTDIR/bench-title.txt
pango-view --font="Roboto Condensed" -qo "$DESKTOP/title.png" "$CURRENTDIR/bench-title.txt"
pango-view --font="Roboto Condensed" -qo "$DESKTOP/sysbench.png" /home/$USER/Desktop/sysbench.txt
pango-view --font="Roboto Condensed" -qo "$DESKTOP/glmark2.png" /home/$USER/Desktop/glmark2.txt

# Join the PNG images together
convert "$DESKTOP/sysbench.png" +append "$DESKTOP/sysbenchmark.png"
convert "$DESKTOP/glmark2.png" +append "$DESKTOP/glmark2mark.png"
convert "$DESKTOP/sysbenchmark.png" \
    "$DESKTOP/glmark2mark.png" \
    -append "$DESKTOP/Benchmarks.png"
convert -bordercolor black -border 2 "$DESKTOP/Benchmarks.png" "$DESKTOP/results.png"

# Remove the text files
rm "$DESKTOP/glmark2.txt"
rm "$DESKTOP/sysbench.txt"

# Remove the temporary image files
rm "$DESKTOP/sysbenchmark.png"
rm "$DESKTOP/glmark2mark.png"

# Make one PNG file
convert "$DESKTOP/sysbench.png" \
    "$DESKTOP/glmark2.png" \
    +append "$DESKTOP/benchmarks.png"

# Convert results.png benchmark to a PDF file to imported into specs.tex
img2pdf "$DESKTOP/results.png" -o "$DESKTOP/results.pdf"

echo -e "${LTGREEN}*** ${WHITE}Starting detection and document creation ! ${LTGREEN}*** ${NC}"
# create a latex document at /home/$USER/Desktop/specs.tex
{
	printf '\\documentclass{article}\n'
	printf '\\usepackage{parskip}\n'
	printf '\\usepackage[legalpaper, portrait, margin=0.5in]{geometry}\n'
	printf '\\usepackage{graphicx}\n'
	printf '\\title{System Specifications}\n'
	printf '\\begin{document}\n'
} > "$DESKTOP/specs.tex" # NOT >> for the first write

# First output the title
printf '\\maketitle\n' >> "$DESKTOP/specs.tex"
printf '\\vspace{-5em}' >> "$DESKTOP/specs.tex"

# Now let's create the barcode
# if no OEM barcode, use mac address: cat /sys/class/net/*/address | head -n 1 >> /home/$USER/Desktop/barcode.txt
# Wrap bottom statement in an IF statement or maybe set this as a varable before
# 02/14/2023 - Happy Valentines Day - if SLEN is less than 4 characters it's not a proper serial number, use mac address
echo -e "${LTGREEN}*** ${WHITE}Creating the barcode ! ${LTGREEN}*** ${NC}"
if [[ $SLEN -lt 4 || $SERIALNO == "System Serial Number" || $SERIALNO == "To be filled by O.E.M." || $SERIALNO == "Default string" || $SERIALNO =~ [^A-Za-z0-9] ]]; then
	# set the serial number to the mac address if any of the above apply
	echo "$FAMILY"
	cat /sys/class/net/*/address | head -n 1 | sed 's/://g' | tr -d "_" >> "$DESKTOP/barcode.txt"
	SERIALNO=$(cat /sys/class/net/*/address | head -n 1 | sed 's/://g')
else
	echo "$FAMILY"
	sudo dmidecode -t 1 | grep "Serial" | cut -c 17- | tr -d "_" >> "$DESKTOP/barcode.txt"
	SERIALNO=$(sudo dmidecode -t 1 | grep "Serial" | cut -c 17-)
fi

barcode -e "128" -g "144x72" -E -i "$DESKTOP/barcode.txt"  -o "$DESKTOP/barcode.eps"
cd "$DESKTOP" || exit
epspdf barcode.eps barcode.pdf
pdfcrop --margins '0 10 10 0' barcode.pdf serial.pdf

# detect Model/Mfg information
echo -e "${LTGREEN}*** ${WHITE}Detecting system information ! ${LTGREEN}*** ${NC}"
echo "\section{Model}" >> "$DESKTOP/specs.tex"
if [[ $FAMILY == 'To be filled by O.E.M.' || $FAMILY == 'To Be Filled By O.E.M.' ]]; then
	{
		echo "Motherboard: " "$MMFG" "Model: " "$MMODEL" | tr -d "_"
		printf '\\newline\n'
	} >> "$DESKTOP/specs.tex"
fi
{
	sudo dmidecode -t 1 | grep "Manufacturer"
	echo "\quad"
	sudo dmidecode -t 1 | grep "Product Name" | tr -d "_"
	printf '\\newline\n'
	sudo dmidecode -t 1 | grep "Family" | tr -d "_"
	echo "\quad"
	sudo dmidecode -t 1 | grep "Serial" | tr -d "_"
	printf '\\newline\n'
	echo "\includegraphics{serial.pdf}"
	echo "\includegraphics{results.pdf}"
	printf '\\newline\n'
} >> "$DESKTOP/specs.tex"

# Now remove all the files that got created to generate the pdf
rm barcode.txt barcode.eps barcode.pdf

# detect CPU information
{
	printf '\\section{CPU}\n'
	sudo dmidecode -t 4 | grep "Manufacturer" | tr -d "_"
	printf '\\quad\n'
	# sudo dmidecode -t 4 | grep "Version"
	echo 'Model: ' "$CPUMODEL" | tr -d "_"
	printf '\\newline\n'
	sudo dmidecode -t 4 | grep "Core Count"
	printf '\\quad\n'
	sudo dmidecode -t 4 | grep "Thread Count"
	printf '\\newline\n'
} >> "$DESKTOP/specs.tex"

#detect RAM information
{
	printf '\\section{RAM}\n'
	#vmstat -sS M | grep "total memory"
	#lshw -c memory | grep size
	sudo lshw -short -class memory | grep "System" | sed 's/^[^m]*memory//'
	echo "\quad"
	sudo dmidecode -t memory | grep "Maximum Capacity"
	echo "\quad"
	# unfortunately some manufacurers put SDRAM in place of DDR2, DDR3, so this may not show
	sudo dmidecode -t 17 | grep -m 1 "Type: DDR"
	printf '\\newline\n'
	sudo dmidecode -t 17 | grep "Configured Memory Speed"
} >> "$DESKTOP/specs.tex"

#detect GRAPHICS information
{
	printf '\\section{GRAPHICS}\n'
	sudo lshw -C Display | grep product | sed 's/&//g'
	printf '\\newline\n'  # this and the following line added 20/01/2023
} >> "$DESKTOP/specs.tex"

if [[ $VLEN -gt 2 ]]; then
	echo "$VRAM" >> "$DESKTOP/specs.tex"
else
	glxinfo | grep "Total available memory" | cut -c 5- >> "$DESKTOP/specs.tex"
fi

{
	printf '\\newline\n'
	glxinfo | grep "OpenGL version"
} >> "$DESKTOP/specs.tex"

#detect hard drive
printf '\\section{HardDrive}\n' >> "$DESKTOP/specs.tex"
# check for an eMMC drive
if [[ -n "$EMMC" ]]; then
	sudo fdisk -l | grep "$EMMC" | head -1 | tr -d "_" >> "$DESKTOP/specs.tex"
else
	echo "No EMMC drive"
fi

if lshw -short | grep nvme; then
	{
	lshw -short | grep -m1 nvme | cut -c 17- | tr -d "_"
	printf '\\newline\n'
	} >> "$DESKTOP/specs.tex"
fi

for SDDRIVE in $SDDRIVE; do
	HDDFAMILY=$(sudo smartctl -d ata -a -i "$SDDRIVE" | grep "Model")
	if [ ! -z "$HDDFAMILY" ]; then
#		sudo smartctl -d ata -a -i "$SDDRIVE" | grep "Model Family" >> /home/$USER/Desktop/specs.tex
#		printf '\\newline\n' >> /home/$USER/Desktop/specs.tex

		sudo smartctl -d ata -a -i "$SDDRIVE" | grep "Device Model" | tr -d "_" >> "$DESKTOP/specs.tex"
		printf '\\newline\n' >> "$DESKTOP/specs.tex"

		sudo smartctl -d ata -a -i "$SDDRIVE" | grep "User Capacity"  >> "$DESKTOP/specs.tex"
		printf '\\newline\n' >> "$DESKTOP/specs.tex"
	else
		echo "This is not actually a hard drive, nor an SSD, but a media drive."
	fi
done

# detect CD/DVD drive
# If there's none then nothing happens
if lshw -short | grep cdrom; then
	{
		echo "\\section{DVDDrive}"
		cd-drive | grep Vendor | tr -d "_"
		echo "\quad"
		cd-drive | grep Model | tr -d "_"
		echo "\quad"
		cd-drive | grep Revision | tr -d "_"
	} >> "$DESKTOP/specs.tex"
fi

# Detect network card information
{
	echo "\\section{Network}"
#	sudo lshw -class network | grep product
	echo "$NETWORK" | tr -d "_"
	printf '\\newline\n' >> "$DESKTOP/specs.tex"
} >> "$DESKTOP/specs.tex"

# Wifi and Bluetooth logos
# consider more "llll" left-justified columns (or c or r)
echo "\begin{tabular}{@{}lll}" >> "$DESKTOP/specs.tex"
LOGOS="" # to go on line(s) below the details:
if [[ "$BTVERSION" ]]; then
	echo "Bluetooth $BTVERSION &" >> "$DESKTOP/specs.tex"
	cp "$CURRENTDIR/btlogo.png" "$DESKTOP/btlogo.png"
	LOGOS="\\raisebox{-0.3ex}{\includegraphics{btlogo.png}} & "
else
	echo "No Bluetooth"
fi
if [[ "$WIFIVERSION" ]]; then
	# consider adding the "&" if more columns
	echo "$WIFIVERSION" >> "$DESKTOP/specs.tex"
	cp "$CURRENTDIR/wifilogo.png" "$DESKTOP/wifilogo.png"
	LOGOS="$LOGOS\\raisebox{-0.3ex}{\includegraphics{wifilogo.png}}"
else
	echo "No Wifi"
fi
echo '\\' >> "$DESKTOP/specs.tex" # single-quoted for actual double \
echo "$LOGOS" >> "$DESKTOP/specs.tex"
echo "\end{tabular}" >> "$DESKTOP/specs.tex"

#detect sound card information
{
	echo "\\section{Sound}"
	sudo lshw -class sound | grep -m 1 product | tr -d "_"
} >> "$DESKTOP/specs.tex"

echo -e "${LTGREEN}*** ${WHITE}Detecting Laptop-specific hardware ! ${LTGREEN}*** ${NC}"
if [ -d "/proc/acpi/button/lid" ]; then
	# install necessary extra software
	echo "\\section{Laptop Specific}" >> "$DESKTOP/specs.tex"
	if acpi -V | grep "design capacity"; then
		acpi -V | grep "design capacity" | tr -d "_" >> "$DESKTOP/specs.tex"
		printf '\\newline\n' >> "$DESKTOP/specs.tex"
	fi
	# display the resolution
	xrandr | grep -m1 connected | tr -d "_" >> "$DESKTOP/specs.tex"
	printf '\\newline\n' >> "$DESKTOP/specs.tex"

	# Take an average watts measurement on idle
	echo -e "${LTBLUE}*** ${WHITE} Measuring Power Draw on IDLE for 60 seconds! ${LTBLUE}*** ${NC}"
	printf "IDLE " >> "$DESKTOP/specs.tex"
	sudo powerstat -cDHRf 2 | grep "Watts on average" >> "$DESKTOP/specs.tex"
	printf '\\newline\n' >> "$DESKTOP/specs.tex"

	# fix mouse cannot right or left click when laptop lid is closed
	sudo sed -i 's/IgnoreLid=false/IgnoreLid=true/g' /etc/UPower/UPower.conf
fi

# Added OS because we're building too many machines without specifying which version of Xubuntu is installed.
echo "\\section{Operating System}" >> "$DESKTOP/specs.tex"
echo $OSFAMILY $XDG_CURRENT_DESKTOP | tr -d "_" >> "$DESKTOP/specs.tex"

##########################
### Now create the PDF ###
##########################

# close the document
echo -e "${LTGREEN}*** ${WHITE}Creating final document ! ${LTGREEN}*** ${NC}"
printf '\\end{document}\n' >> "$DESKTOP/specs.tex"
cd "$DESKTOP" || exit


# the line below strips out any underscores _ from specs.tex
sed -i s/_//g specs.tex
pdflatex specs.tex  > /dev/null

cp specs.pdf "$SERIALNO.pdf"
if ping -c 1 -W 1 truenas ; then
	smbclient //truenas/share -U "linuxuser" -c "put $SERIALNO.pdf $SERIALNO.pdf"
else
	echo "Done, this is not at The Working Centre, so exiting here."
fi

cd "$DESKTOP" || exit
rm specs.log specs.aux serial.pdf specs.tex # sysbench.pdf glmark2.pdf > /dev/null
# Remove the images that we no longer need because they are one PDF -- results.pdf
rm "$DESKTOP/sysbench.png" \
    "$DESKTOP/glmark2.png" \
    "$DESKTOP/results.png" \
    "$DESKTOP/Benchmarks.png" \
    "$DESKTOP/benchmarks.png" \
    "$DESKTOP/title.png" \
    "$DESKTOP/wifilogo.png" \
    "$DESKTOP/btlogo.png" > /dev/null

# Now remove the specs.pdf because we've created SERIALNO.PDF
rm specs.pdf  > /dev/null
rm results.pdf > /dev/null

if [ -f "$DESKTOP/small_display.thm" ]; then
	rm "$DESKTOP/small_display.thm"
fi

# set up the sensors
echo -e "${RED}*** ${WHITE}\e[5m Detecting sensors - This may take 45 seconds \e[0m ${RED}*** ${NC}"
sudo sensors-detect --auto > /dev/null
if [ -n "$COREDETECT" ]; then
	echo "*** CPU Core Temperatures ***" > "$DESKTOP/sensors.txt"
	sensors | grep "Core " >> "$DESKTOP/sensors.txt"
else
	echo "Cores may be referred to as something else, so for now not showing temps"
fi

if [ -n "$AMDTDIE" ]; then
	echo "*** CPU Core Temperatures ***" > "$DESKTOP/sensors.txt"
	echo "AMD CPU Temperature average: $AMDTDIE " >> "$DESKTOP/sensors.txt"
else
	echo "Not a recognized AMD CPU."
fi

# Check for an NVidia card, if there is one write the temps to sensors.txt
NVIDIASMI=/usr/bin/nvidia-smi
if [ -f "$NVIDIASMI" ]; then
	NVIDIAGPUTEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader)
	echo "*** NVidia GPU Temperature ***" >> "$DESKTOP/sensors.txt"
	echo "NVidia GPU: $NVIDIAGPUTEMP" >> "$DESKTOP/sensors.txt"
fi
sensors | grep "Tdie:" | cut -c 15-
# testing nvme status - write to sensors.txt

if [ -n "$NVME" ]; then
	NVMEDATAREAD=$(sudo nvme smart-log $NVMENAME | grep "Data Units Read")
	NVMEDATAWRITTEN=$(sudo nvme smart-log $NVMENAME | grep "Data Units Written")
	echo "Writing NVME read/write to sensors.txt data file"
	echo -e "\n" >> "$DESKTOP/sensors.txt"
	echo "*** NVMe Read/Write Information ***" >> "$DESKTOP/sensors.txt"
	echo $NVMEDATAREAD >> "$DESKTOP/sensors.txt"
	echo $NVMEDATAWRITTEN >> "$DESKTOP/sensors.txt"
else
	echo "This computer does not have an NVMe drive"
fi

# Write SSD Life information to sensors.txt

for SDDRIVE in $SDDRIVE; do
	HDDFAMILY=$(sudo smartctl -d ata -a -i "$SDDRIVE" | grep "Model")
	if [ ! -z "$HDDFAMILY" ]; then
		SSDTEST=$(sudo smartctl -i $SDDRIVE | grep "TRIM")
		if [ -n "$SSDTEST" ]; then
			SSDWRITES=$(sudo smartctl -a $SDDRIVE | grep "241" | cut -c 88-)
			SSDREADS=$(sudo smartctl -a $SDDRIVE | grep "242" | cut -c 88-)
			LBA=$(sudo smartctl -a $SDDRIVE | grep "241" | grep "LBA")
			if [ -n "$LBA" ]; then
				SSDWRITES=$(( $SSDWRITES/2097152 ))
			else
				echo "Non-Samsung SSD"
			fi
			echo "*** Writing SSD Information ***"
			echo "SSD Reads: $SSDREADS" >> "$DESKTOP/sensors.txt"
			echo "SSD Writes: $SSDWRITES" >> "$DESKTOP/sensors.txt"
		else
			echo "No SSD"
		fi
	else
		echo "This is not actually a hard drive, nor an SSD, but a media drive."
	fi
done

echo $BATPERCENT
case $BATPERCENT in
    "")
        echo "This is either a desktop, or it has no battery!"
        ;;
    100|9[0-9])
        echo -e "${LTGREEN}\e[5m Great Battery! Add \$20 to the price of the laptop! \e[0m${NC}"
        ;;
    8[0-9])
        echo "Good Battery, normal price."
        ;;
    7[0-9])
        echo "Usable Battery, normal price."
        ;;
    *)
        echo -e "${REDWHITE}\e[5m Ideally, this battery should be replaced, or subtract -\$20 from the price of the laptop \e[0m${NC}"
        ;;
esac
    
# If the BIOS is 2015 or later try to refresh and update the BIOS
if [ "$BIOSYEAR" -lt 2015 ]; then # older than 2015
    echo "The BIOS is older than 2015 (Year: $BIOSYEAR)"
else
    echo "The BIOS is from 2015 or newer (Year: $BIOSYEAR) so trying to do any firmware updates"
    fwupdmgr refresh
    fwupdmgr get-updates
    fwupdmgr update
fi
