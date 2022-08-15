#!/bin/bash
# Copyright 2002 Charles McColm, chaslinux@gmail.com
# Licensed under GPLv3, the General Public License v3.0

# update the system because the script might not work if old software is installed
sudo apt update && sudo apt -y upgrade

# install necessary extra software
sudo apt -y install smartmontools # for hard drives
sudo apt -y install libcdio-utils # for cd-drives
sudo apt -y install acpi # for power information on laptops
sudo apt -y install texlive-latex-base # to make pdfs
sudo apt -y install barcode # to create barcodes
# Note: I don't like installing all these extra tools for one tool.
sudo apt -y install texlive-extra-utils # So we can create convert eps barcode to pdf then crop
sudo apt -y install texlive-pictures # more barcode handling

# create a latex document at /home/$USER/Desktop/specs.tex
if [ ! -f /home/$USER/Desktop/specs.tex ]; then
	echo "creating /home/$USER/Desktop/specs.tex"
	touch /home/$USER/Desktop/specs.tex
	echo "\documentclass{article}" >> /home/$USER/Desktop/specs.tex
	echo "\usepackage[legalpaper, portrait, margin=0.5in]{geometry}" >> /home/$USER/Desktop/specs.tex
	echo "\usepackage{graphicx}" >> /home/$USER/Desktop/specs.tex
	echo "\title{System Specifications}" >> /home/$USER/Desktop/specs.tex
	echo "\begin{document}" >> /home/$USER/Desktop/specs.tex
fi

# First output the title
echo "\maketitle" >> /home/$USER/Desktop/specs.tex

# Now let's create the barcode
sudo dmidecode -t 1 | grep "Serial" | cut -c 17- >> /home/$USER/Desktop/barcode.txt
barcode -e 128 -i /home/$USER/Desktop/barcode.txt  -o /home/$USER/Desktop/barcode.eps
cd /home/$USER/Desktop
epspdf barcode.eps barcode.pdf
pdfcrop --margins '0 10 10 0' barcode.pdf serial.pdf

# detect Model/Mfg information
echo "\section{Model}" >> /home/$USER/Desktop/specs.tex
sudo dmidecode -t 1 | grep "Manufacturer"  >> /home/$USER/Desktop/specs.tex
echo "\quad" >> /home/$USER/Desktop/specs.tex
sudo dmidecode -t 1 | grep "Product Name" >> /home/$USER/Desktop/specs.tex
echo "\newline" >> /home/$USER/Desktop/specs.tex
sudo dmidecode -t 1 | grep "Family" >> /home/$USER/Desktop/specs.tex
echo "\quad" >> /home/$USER/Desktop/specs.tex
sudo dmidecode -t 1 | grep "Serial" >> /home/$USER/Desktop/specs.tex
echo "\newline" >> /home/$USER/Desktop/specs.tex
echo "\includegraphics{serial.pdf}" >> /home/$USER/Desktop/specs.tex
echo "\newline" >> /home/$USER/Desktop/specs.tex
# Now remove all the files that got created to generate the pdf
rm barcode.txt barcode.eps barcode.pdf

#detect CPU information
echo "\section{CPU}" >> /home/$USER/Desktop/specs.tex
sudo dmidecode -t 4 | grep "Manufacturer" >> /home/$USER/Desktop/specs.tex
echo "\quad" >> /home/$USER/Desktop/specs.tex
sudo dmidecode -t 4 | grep "Version" >> /home/$USER/Desktop/specs.tex
echo "\newline" >> /home/$USER/Desktop/specs.tex
sudo dmidecode -t 4 | grep "Core Count" >> /home/$USER/Desktop/specs.tex
echo "\quad" >> /home/$USER/Desktop/specs.tex
sudo dmidecode -t 4 | grep "Thread Count" >> /home/$USER/Desktop/specs.tex

#detect RAM information
echo "\section{RAM}" >> /home/$USER/Desktop/specs.tex
#vmstat -sS M | grep "total memory" >> /home/$USER/Desktop/specs.tex
#lshw -c memory | grep size >> /home/$USER/Desktop/specs.tex
sudo lshw -short | grep "System Memory" | sed 's/^[^m]*memory//' >> /home/$USER/Desktop/specs.tex
echo "\quad" >> /home/$USER/Desktop/specs.tex
sudo dmidecode -t memory | grep "Maximum Capacity" >> /home/$USER/Desktop/specs.tex
echo "\quad" >> /home/$USER/Desktop/specs.tex
# unfortunately some manufacurers put SDRAM in place of DDR2, DDR3, so this may not show
sudo dmidecode -t 17 | grep -m 1 "Type: DDR" >> /home/$USER/Desktop/specs.tex
echo "\newline" >> /home/$USER/Desktop/specs.tex
sudo dmidecode -t 17 | grep "Configured Memory Speed" >> /home/$USER/Desktop/specs.tex

#detect GRAPHICS information
echo "\section{GRAPHICS}" >> /home/$USER/Desktop/specs.tex
sudo lshw -C Display | grep product | sed '/s/&//g' >> /home/$USER/Desktop/specs.tex
echo "\newline" >> /home/$USER/Desktop/specs.tex
glxinfo | grep "OpenGL version" >> /home/$USER/Desktop/specs.tex

#detect hard drive
echo "\section{HardDrive}" >> /home/$USER/Desktop/specs.tex
if lshw -short | grep nvme; then
	lshw -short | grep -m1 nvme | cut -c 17- >> /home/$USER/Desktop/specs.tex
	echo "\newline" >> /home/$USER/Desktop/specs.tex
fi
if sudo smartctl -d ata -a -i /dev/sda | grep "Model Family"; then
	sudo smartctl -d ata -a -i /dev/sda | grep "Model Family" >> /home/$USER/Desktop/specs.tex
	echo "\newline" >> /home/$USER/Desktop/specs.tex
fi
sudo smartctl -d ata -a -i /dev/sda | grep "Device Model" >> /home/$USER/Desktop/specs.tex
echo "\newline" >> /home/$USER/Desktop/specs.tex
sudo smartctl -d ata -a -i /dev/sda | grep "User Capacity" >> /home/$USER/Desktop/specs.tex


# detect CD/DVD drive
# If there's none then nothing happens
if lshw -short | grep cdrom; then
	echo "\section{DVDDrive}" >> /home/$USER/Desktop/specs.tex
	cd-drive | grep Vendor >> /home/$USER/Desktop/specs.tex
	echo "\quad" >> /home/$USER/Desktop/specs.tex
	cd-drive | grep Model >> /home/$USER/Desktop/specs.tex
	echo "\quad" >> /home/$USER/Desktop/specs.tex
	cd-drive | grep Revision >> /home/$USER/Desktop/specs.tex
fi

#detect network card information
echo "\section{Network}" >> /home/$USER/Desktop/specs.tex
sudo lshw -class network | grep product >> /home/$USER/Desktop/specs.tex

#detect sound card information
echo "\section{Sound}" >> /home/$USER/Desktop/specs.tex
sudo lshw -class sound | grep -m 1 product >> /home/$USER/Desktop/specs.tex

if [ -d "/proc/acpi/button/lid" ]; then
	# install necessary extra software
	echo "\section{Laptop Specific}" >> /home/$USER/Desktop/specs.tex
	if acpi -V | grep "design capacity"; then
		acpi -V | grep "design capacity" >> /home/$USER/Desktop/specs.tex
		echo "\newline" >> /home/$USER/Desktop/specs.tex
	fi
	# display the resolution
	xrandr | grep -m1 connected >> /home/$USER/Desktop/specs.tex
fi


echo "\end{document}" >> /home/$USER/Desktop/specs.tex
cd /home/$USER/Desktop
# the line below strips out any underscores _ from specs.tex
sed -i s/\_//g specs.tex
pdflatex specs.tex

# lastly remove serial.pdf and other files once the specs.pdf is created
cd /home/$USER/Desktop
rm specs.log specs.aux serial.pdf
