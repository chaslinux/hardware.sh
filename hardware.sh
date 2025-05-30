#!/bin/bash
# Copyright 2022, 2023, 2024, 2025 Charles McColm, chaslinux@gmail.com
# Licensed under GPLv3, the General Public License v3.0

# Add some colour to the script
WHITE='\033[1;37m'
NC='\033[0m'
LTGREEN='\033[1;32m'
PURPLE='\033[0;35m'

# Variables
CURRENTDIR=$(pwd)
FAMILY=$(sudo dmidecode -t 1 | grep "Family" | cut -c 10-)
SERIALNO=$(sudo dmidecode --string system-serial-number)
SLEN=$(echo "$SERIALNO" | awk '{print length}') # added this because SERIAL NUMBER
MMFG=$(sudo dmidecode -t 2 | grep Manu | cut -c 16-)
MMODEL=$(sudo dmidecode -t 2 | grep Product | cut -c 15-)
CPUMODEL=$(grep -m 1 "model name" /proc/cpuinfo | cut -c 14-)
VRAM=$(glxinfo | grep "Video memory")
VLEN=$(echo "$VRAM" | awk '{print length}') # vram character length
# Note: MMODEL includes a space before the model
#SDDRIVE=$(smartctl --scan | cut -c -8)
SDDRIVE=$(ls -1 /dev/sd?)
EMMC=$(ls -l /dev/mmcblk*)
HDDFAMILY=$(sudo smartctl -d ata -a -i "$SDDRIVE" | grep "Model")
OSFAMILY=$(lsb_release -a | grep "Description" | cut -c 14-)
OSRELEASE=$(lsb_release -a | grep "Release:" | cut -c 10-)
RAMSIZE=$(sudo lshw -short -class memory | grep "System" | sed 's/^[^m]*memory//' | awk '{$1=$1};1')
GRAPHICS=$(sudo lshw -C Display | grep product | sed 's/&//g' | cut -c 17-)
PROD1=$(sudo dmidecode -t 1 | grep "Manufacturer" | cut -c 16-)
PROD2=$(sudo dmidecode -t 1 | grep "Product Name" | cut -c 16-)
PRODUCT="$PROD1 $PROD2"


### There is a bug in the ghostscript included with Imagemagick in Linux Mint 21.3
### that prevents convert from converting images to PDFs. It's a security issue so
### the team blocked using ImageMagick to create PDFs in policy.xml.
### The following lines comment out that line in policy.xml so we can convert our
### images to PDF. At the end of the file we remove the comment.

if [ $OSRELEASE=="21.3" ]; then
	sudo sed -i '/<policy domain="coder" rights="none" pattern="PDF" \/>/d' /etc/ImageMagick-6/policy.xml 
fi

# update the system because the script might not work if old software is installed
echo -e "${LTGREEN}*** ${WHITE}Running updates ! ${LTGREEN}*** ${NC}"
sudo apt update && sudo apt -y upgrade

echo -e "${LTGREEN}*** ${WHITE}Installing Software needed for LaTeX and PDF creation ! ${LTGREEN}*** ${NC}"
# install necessary extra software
sudo apt -y install smbclient # so we can copy the serialno.pdf to our TrueNAS server
sudo apt -y install smartmontools # for hard drives
sudo apt -y install libcdio-utils # for cd-drives
sudo apt -y install acpi # for power information on laptops
sudo apt -y install texlive-latex-base # to make pdfs
sudo apt -y install texlive-latex-extra # needed for changes on 05/28/2025
sudo apt -y install barcode # to create barcodes
# Note: I don't like installing all these extra tools for one tool.
sudo apt -y install texlive-extra-utils # So we can create convert eps barcode to pdf then crop
sudo apt -y install texlive-pictures # more barcode handling
# For new benchmarking features
sudo apt install pango1.0-tools sysbench glmark2 imagemagick -y
sudo apt install img2pdf -y

###################################################
### This area is for the benchmarks development ###
###################################################

if [ -f /home/"$USER"/Desktop/sysbench.txt ]; then
	echo "Removing sysbench.txt..."
	rm /home/"$USER"/Desktop/sysbench.txt
else
	echo "No sysbench.txt file, creating one."
fi

if [ -f /home/"$USER"/Desktop/glmark2.txt ]; then
	echo "Removing glmark2.txt..."
	rm /home/"$USER"/Desktop/glmark2.txt
else
	echo "No glmark2.txt file, creating one."
fi

if [ -f /home/"$USER"/Desktop/sysbench.png ]; then
	echo "Removing sysbench.png"
	rm /home/"$USER"/Desktop/sysbench.png
fi
if [ -f /home/"$USER"/Desktop/glmark2.png ]; then
	echo "Removing glmark2.png"
	rm /home/"$USER"/Desktop/glmark2.png
fi

# create the sysbench text file
echo -n "CPU: " > /home/"$USER"/Desktop/sysbench.txt
echo "Now running sysbench... be patient for a few seconds..."
sysbench cpu --cpu-max-prime=10000 run | grep "events per second" | cut -c 25- >> /home/"$USER"/Desktop/sysbench.txt

# create the glmark2 text file
echo -n "GLMark2: " > /home/"$USER"/Desktop/glmark2.txt
echo "Now running glmark2... be patient for a few seconds..."
glmark2 -b :duration=2.0 -b shading -b build -b :duration-5.0 -b texture | grep "glmark2 Score:" | cut -c 50- >> /home/"$USER"/Desktop/glmark2.txt

# Now create the images to be incorporated into the PDF
pango-view --font="Ubuntu Sans Ultra-Bold" -qo /home/"$USER"/Desktop/title.png $CURRENTDIR/bench-title.txt
pango-view --font="Ubuntu Sans Ultra-Bold" -qo /home/"$USER"/Desktop/sysbench.png /home/"$USER"/Desktop/sysbench.txt
pango-view --font="Ubuntu Sans Ultra-Bold" -qo /home/"$USER"/Desktop/glmark2.png /home/"$USER"/Desktop/glmark2.txt

pango-view --font="Roboto Condensed" -qo /home/"$USER"/Desktop/mtitle.png $CURRENTDIR/bench-title.txt
pango-view --font="Roboto Condensed" -qo /home/"$USER"/Desktop/msysbench.png /home/"$USER"/Desktop/sysbench.txt
pango-view --font="Roboto Condensed" -qo /home/"$USER"/Desktop/mglmark2.png /home/"$USER"/Desktop/glmark2.txt

# Make the small benchmark image
convert /home/"$USER"/Desktop/msysbench.png /home/"$USER"/Desktop/mglmark2.png +append /home/"$USER"/Desktop/mbenchmarks.png
convert /home/"$USER"/Desktop/mtitle.png /home/"$USER"/Desktop/mbenchmarks.png -append /home/"$USER"/Desktop/mBenchmarks.png
convert -bordercolor black -border 2 /home/"$USER"/Desktop/mBenchmarks.png /home/"$USER"/Desktop/mresults.png
convert /home/"$USER"/Desktop/mresults.png /home/"$USER"/Desktop/mresults.pdf

# Join the PNG images together
convert /home/"$USER"/Desktop/sysbench.png /home/"$USER"/Desktop/glmark2.png +append /home/"$USER"/Desktop/benchmarks.png
convert /home/"$USER"/Desktop/title.png /home/"$USER"/Desktop/benchmarks.png -append /home/"$USER"/Desktop/Benchmarks.png
convert -bordercolor black -border 2 /home/"$USER"/Desktop/Benchmarks.png /home/"$USER"/Desktop/results.png

# Remove the text files
rm /home/"$USER"/Desktop/glmark2.txt
rm /home/"$USER"/Desktop/sysbench.txt

# Remove the small image files
rm /home/"$USER"/Desktop/mtitle.png
rm /home/"$USER"/Desktop/mglmark2.png
rm /home/"$USER"/Desktop/msysbench.png
rm /home/"$USER"/Desktop/mBenchmarks.png
rm /home/"$USER"/Desktop/mbenchmarks.png
rm /home/"$USER"/Desktop/mresults.png

# Make one PNG file
convert /home/"$USER"/Desktop/sysbench.png /home/"$USER"/Desktop/glmark2.png +append /home/"$USER"/Desktop/benchmarks.png

# Convert results.png benchmark to a PDF file to imported into specs.tex
img2pdf /home/"$USER"/Desktop/results.png -o /home/"$USER"/Desktop/results.pdf

echo -e "${LTGREEN}*** ${WHITE}Starting detection and document creation ! ${LTGREEN}*** ${NC}"
# create a latex document at /home/"$USER"/Desktop/specs.tex
if [ ! -f /home/"$USER"/Desktop/specs.tex ]; then
	echo "creating /home/$USER/Desktop/specs.tex"
	touch /home/"$USER"/Desktop/specs.tex
	{
	printf '\\documentclass{article}\n'
	printf '\\usepackage{parskip}\n'
	printf '\\usepackage[legalpaper, portrait, margin=0.5in]{geometry}\n'
	printf '\\usepackage{graphicx}\n'
	printf '\\title{System Specifications}\n'
	printf '\\begin{document}\n'
	} >> /home/"$USER"/Desktop/specs.tex
fi

# First output the title
printf '\\maketitle\n' >> /home/"$USER"/Desktop/specs.tex

# Now let's create the barcode
# if no OEM barcode, use mac address: cat /sys/class/net/*/address | head -n 1 >> /home/"$USER"/Desktop/barcode.txt
# Wrap bottom statement in an IF statement or maybe set this as a varable before
# 02/14/2023 - Happy Valentines Day - if SLEN is less than 4 characters it's not a proper serial number, use mac address
echo -e "${LTGREEN}*** ${WHITE}Creating the barcode ! ${LTGREEN}*** ${NC}"
if [[ $SLEN -lt 4 || $SERIALNO == "System Serial Number" || $SERIALNO == "To be filled by O.E.M." || $SERIALNO == "Default string" || $SERIALNO =~ [^A-Za-z0-9] ]]
	then    # set the serial number to the mac address if any of the above apply
		echo "$FAMILY"
		cat /sys/class/net/*/address | head -n 1 | sed 's/://g' >> /home/"$USER"/Desktop/barcode.txt
		SERIALNO=$(cat /sys/class/net/*/address | head -n 1 | sed 's/://g')
	else
		echo "$FAMILY"
		sudo dmidecode -t 1 | grep "Serial" | cut -c 17- >> /home/"$USER"/Desktop/barcode.txt
		SERIALNO=$(sudo dmidecode -t 1 | grep "Serial" | cut -c 17-)
fi

barcode -e "39" -g "144x72" -E -i /home/"$USER"/Desktop/barcode.txt  -o /home/"$USER"/Desktop/barcode.eps
cd /home/"$USER"/Desktop || exit
epspdf barcode.eps barcode.pdf
pdfcrop --margins '0 10 10 0' barcode.pdf serial.pdf

# detect Model/Mfg information
echo -e "${LTGREEN}*** ${WHITE}Detecting system information ! ${LTGREEN}*** ${NC}"
echo "\section{Model}" >> /home/"$USER"/Desktop/specs.tex
if [[ $FAMILY == 'To be filled by O.E.M.' || $FAMILY == 'To Be Filled By O.E.M.' ]]
	then
		{
		echo "Motherboard: " "$MMFG" "Model: " "$MMODEL"
		printf '\\newline\n'
		} >> /home/"$USER"/Desktop/specs.tex
fi
{
	sudo dmidecode -t 1 | grep "Manufacturer" 
	echo "\quad" 
	sudo dmidecode -t 1 | grep "Product Name" 
	printf '\\newline\n' 
	sudo dmidecode -t 1 | grep "Family" 
	echo "\quad" 
	sudo dmidecode -t 1 | grep "Serial"
	printf '\\newline\n' 
	echo "\includegraphics{serial.pdf}" 
	echo "\includegraphics{results.pdf}"
	printf '\\newline\n' 
} >> /home/"$USER"/Desktop/specs.tex

# Now remove all the files that got created to generate the pdf
rm barcode.txt barcode.eps barcode.pdf

# detect CPU information
{
	printf '\\section{CPU}\n'
	sudo dmidecode -t 4 | grep "Manufacturer"
	printf '\\quad\n'
	# sudo dmidecode -t 4 | grep "Version"
	echo 'Model: ' "$CPUMODEL"
	printf '\\newline\n'
	sudo dmidecode -t 4 | grep "Core Count"
	printf '\\quad\n'
	sudo dmidecode -t 4 | grep "Thread Count"
	printf '\\newline\n' 
} >> /home/"$USER"/Desktop/specs.tex

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
} >> /home/"$USER"/Desktop/specs.tex

#detect GRAPHICS information
{
printf '\\section{GRAPHICS}\n'
sudo lshw -C Display | grep product | sed 's/&//g'
printf '\\newline\n'  # this and the following line added 20/01/2023
} >> /home/"$USER"/Desktop/specs.tex

if [[ $VLEN -gt 2 ]]
	then
		echo "$VRAM" >> /home/"$USER"/Desktop/specs.tex 
	else
		glxinfo | grep "Total available memory" | cut -c 5- >> /home/"$USER"/Desktop/specs.tex
fi

{
	printf '\\newline\n' 
	glxinfo | grep "OpenGL version" 
} >> /home/"$USER"/Desktop/specs.tex

#detect hard drive
printf '\\section{HardDrive}\n' >> /home/"$USER"/Desktop/specs.tex
# check for an eMMC drive
if [ $EMMC=="" ];
	then
		echo "No EMMC drive"
	else
		sudo fdisk -l | grep $EMMC | head -1 >> /home/"$USER"/Desktop/specs.tex
fi
if lshw -short | grep nvme; then
    {
	lshw -short | grep -m1 nvme | cut -c 17- 
	printf '\\newline\n' 
	} >> /home/"$USER"/Desktop/specs.tex
fi

for SDDRIVE in $SDDRIVE; do

		HDDFAMILY=$(sudo smartctl -d ata -a -i "$SDDRIVE" | grep "Model")
		if [ ! -z "$HDDFAMILY" ];	

		then
#				sudo smartctl -d ata -a -i "$SDDRIVE" | grep "Model Family" >> /home/"$USER"/Desktop/specs.tex
#				printf '\\newline\n' >> /home/"$USER"/Desktop/specs.tex

				sudo smartctl -d ata -a -i "$SDDRIVE" | grep "Device Model"  >> /home/"$USER"/Desktop/specs.tex
				printf '\\newline\n' >> /home/"$USER"/Desktop/specs.tex

				sudo smartctl -d ata -a -i "$SDDRIVE" | grep "User Capacity"  >> /home/"$USER"/Desktop/specs.tex
				printf '\\newline\n' >> /home/"$USER"/Desktop/specs.tex	

		else
				echo "This is not actually a hard drive, nor an SSD, but a media drive."
		fi
done

#if sudo smartctl -d ata -a -i /dev/sda | grep "Model Family"; then
#	sudo smartctl -d ata -a -i /dev/sda | grep "Model Family" >> /home/"$USER"/Desktop/specs.tex
#	printf '\\newline\n' >> /home/"$USER"/Desktop/specs.tex
#fi
#sudo smartctl -d ata -a -i /dev/sda | grep "Device Model" >> /home/"$USER"/Desktop/specs.tex
#printf '\\newline\n' >> /home/"$USER"/Desktop/specs.tex
#sudo smartctl -d ata -a -i /dev/sda | grep "User Capacity" >> /home/"$USER"/Desktop/specs.tex


# detect CD/DVD drive
# If there's none then nothing happens
if lshw -short | grep cdrom; then
	{
		echo "\section{DVDDrive}" 
		cd-drive | grep Vendor 
		echo "\quad" 
		cd-drive | grep Model 
		echo "\quad" 
		cd-drive | grep Revision 
	} >> /home/"$USER"/Desktop/specs.tex
fi

#detect network card information
{
	echo "\section{Network}" 
	sudo lshw -class network | grep product
} >> /home/"$USER"/Desktop/specs.tex

#detect sound card information
{
	echo "\section{Sound}"
	sudo lshw -class sound | grep -m 1 product
} >> /home/"$USER"/Desktop/specs.tex

echo -e "${LTGREEN}*** ${WHITE}Detecting Laptop-specific hardware ! ${LTGREEN}*** ${NC}"
if [ -d "/proc/acpi/button/lid" ]; then
	# install necessary extra software
	echo "\section{Laptop Specific}" >> /home/"$USER"/Desktop/specs.tex
	if acpi -V | grep "design capacity"; then
		acpi -V | grep "design capacity" >> /home/"$USER"/Desktop/specs.tex
		printf '\\newline\n' >> /home/"$USER"/Desktop/specs.tex
	fi
	# display the resolution
	xrandr | grep -m1 connected >> /home/"$USER"/Desktop/specs.tex

	# fix mouse cannot right or left click when laptop lid is closed
	sudo sed -i 's/IgnoreLid=false/IgnoreLid=true/g' /etc/UPower/UPower.conf

fi

# Added OS because we're building too many machines without specifying which version of Xubuntu is installed.
echo "\section{Operating System}" >> /home/"$USER"/Desktop/specs.tex
echo $OSFAMILY $XDG_CURRENT_DESKTOP >> /home/"$USER"/Desktop/specs.tex

echo -e "${LTGREEN}*** ${WHITE}Creating final document ! ${LTGREEN}*** ${NC}"
printf '\\end{document}\n' >> /home/"$USER"/Desktop/specs.tex
cd /home/"$USER"/Desktop || exit


##########################
### Now create the PDF ###
##########################

# the line below strips out any underscores _ from specs.tex
sed -i s/_//g specs.tex
pdflatex specs.tex

cp specs.pdf $SERIALNO.pdf
if ping -c 1 -W 1 truenas ; then
	smbclient //truenas/share -U "linuxuser" -c "put $SERIALNO.pdf $SERIALNO.pdf"
else
	echo "Done, this is not at The Working Centre, so exiting here."
fi

### Now re-enable the PDF blocking policy in Linux Mint 21.3
if [ $OSRELEASE=="21.3" ]; then
	POLICYCOUNT=$(wc -l < /etc/ImageMagick-6/policy.xml)
	sudo sed -i "$POLICYCOUNT i\\<policy domain=\"coder\" rights=\"none\" pattern=\"PDF\" />\\" /etc/ImageMagick-6/policy.xml
fi

echo "\documentclass{article}" >> small_display.tex
echo "\usepackage{blindtext}" >> small_display.tex
echo "\usepackage{mdframed}" >> small_display.tex
echo "\usepackage[paperheight=5.0in,paperwidth=5.0in,margin=0.15in,heightrounded,showframe]{geometry}"  >> small_display.tex
echo "\usepackage{parskip}"  >> small_display.tex
echo "\usepackage{graphicx}" >> small_display.tex
echo "\usepackage[T1]{fontenc}" >> small_display.tex
echo "\usepackage{tgbonum}" >> small_display.tex

echo "\begin{document}" >> small_display.tex
echo "\begin{table}" >> small_display.tex
echo "\end{table}" >> small_display.tex
echo "\begin{center}" >> small_display.tex
echo "{\fontfamily{qcr}\selectfont" >> small_display.tex
echo "$PRODUCT" >> small_display.tex
echo "}" >> small_display.tex
echo "\end{center}" >> small_display.tex
echo "\begin{center}" >> small_display.tex
echo "\includegraphics{serial.pdf}" >> small_display.tex
echo "\end{center}" >> small_display.tex
#echo "\newline" >> small_display.tex
# echo "\newline" >> small_display.tex
echo "\includegraphics{mresults.pdf}" >> small_display.tex
echo "\newline" >> small_display.tex
echo "\newline" >> small_display.tex
echo "{\fontfamily{put}\selectfont" >> small_display.tex
echo "$CPUMODEL" >> small_display.tex
echo "\newline" >> small_display.tex
echo "$RAMSIZE" >> small_display.tex
echo "\newline" >> small_display.tex
echo "$GRAPHICS" >> small_display.tex
echo "\newline" >> small_display.tex
if [ $EMMC=="" ];
	then
		echo "No EMMC drive"
	else
		sudo fdisk -l | grep $EMMC | head -1 >> /home/"$USER"/Desktop/small_display.tex
fi
if lshw -short | grep nvme; then
    {
	lshw -short | grep -m1 nvme | cut -c 17- 
	echo "\newline" 
	} >> /home/"$USER"/Desktop/small_display.tex
fi

for SDDRIVE in $SDDRIVE; do
		HDDFAMILY=$(sudo smartctl -d ata -a -i "$SDDRIVE" | grep "Model")
		if [ ! -z "$HDDFAMILY" ];	

		then
				sudo smartctl -d ata -a -i "$SDDRIVE" | grep "Device Model" | cut -c 14- >> /home/"$USER"/Desktop/small_display.tex
				echo "\newline" >> /home/"$USER"/Desktop/small_display.tex
		else
				echo "This is not actually a hard drive, nor an SSD, but a media drive."
		fi
done
echo "}" >> small_display.tex
echo "\end{document}" >> small_display.tex
pdflatex small_display.tex

# lastly remove serial.pdf and other files once the specs.pdf is created
cd /home/"$USER"/Desktop || exit
rm specs.log specs.aux serial.pdf specs.tex sysbench.pdf glmark2.pdf
# Remove the images that we no longer need because they are one PDF -- results.pdf
rm /home/"$USER"/Desktop/sysbench.png
rm /home/"$USER"/Desktop/glmark2.png
rm /home/"$USER"/Desktop/results.png 
rm /home/"$USER"/Desktop/Benchmarks.png
rm /home/"$USER"/Desktop/benchmarks.png
rm /home/"$USER"/Desktop/mresults.pdf
rm /home/"$USER"/Desktop/small_display.tex
rm /home/"$USER"/Desktop/small_display.log
rm /home/"$USER"/Desktop/small_display.aux
rm /home/"$USER"/Desktop/title.png
# Now remove the specs.pdf because we've created SERIALNO.PDF
rm specs.pdf 
rm results.pdf

