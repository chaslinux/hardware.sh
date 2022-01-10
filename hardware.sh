#!/bin/bash
# Copyright 2002 Charles McColm, chaslinux@gmail.com
# Licensed under GPLv3, the General Public License v3.0

# install necessary extra software
sudo apt -y install smartmontools # for hard drives
sudo apt -y install libcdio-utils # for cd-drives
sudo apt -y install texlive-latex-base # to make pdfs

# create a latex document at /home/$USER/Desktop/specs.tex
if [ ! -f /home/$USER/Desktop/specs.tex ]; then
	echo "creating /home/$USER/Desktop/specs.tex"
	touch /home/$USER/Desktop/specs.tex
	echo "\documentclass{article}" >> /home/$USER/Desktop/specs.tex
	echo "\usepackage[legalpaper, portrait, margin=1.5in]{geometry}" >> /home/$USER/Desktop/specs.tex
	echo "\title{System Specifications}" >> /home/$USER/Desktop/specs.tex
	echo "\begin{document}" >> /home/$USER/Desktop/specs.tex
fi

# First output the title
echo "\maketitle" >> /home/$USER/Desktop/specs.tex

# detect Model/Mfg information
echo "\section{Model}" >> /home/$USER/Desktop/specs.tex
sudo dmidecode -t 1 | grep "Manufacturer"  >> /home/$USER/Desktop/specs.tex
echo "\quad" >> /home/$USER/Desktop/specs.tex
sudo dmidecode -t 1 | grep "Product Name" >> /home/$USER/Desktop/specs.tex
echo "\newline" >> /home/$USER/Desktop/specs.tex
sudo dmidecode -t 1 | grep "Family" >> /home/$USER/Desktop/specs.tex
echo "\quad" >> /home/$USER/Desktop/specs.tex
sudo dmidecode -t 1 | grep "Serial" >> /home/$USER/Desktop/specs.tex

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
sudo lshw -C Display | grep product >> /home/$USER/Desktop/specs.tex
echo "\newline" >> /home/$USER/Desktop/specs.tex
glxinfo | grep "OpenGL version" >> /home/$USER/Desktop/specs.tex

#detect hard drive
echo "\section{HardDrive}" >> /home/$USER/Desktop/specs.tex
sudo smartctl -d ata -a -i /dev/sda | grep "Model Family" >> /home/$USER/Desktop/specs.tex
echo "\newline" >> /home/$USER/Desktop/specs.tex
sudo smartctl -d ata -a -i /dev/sda | grep "Device Model" >> /home/$USER/Desktop/specs.tex
echo "\newline" >> /home/$USER/Desktop/specs.tex
sudo smartctl -d ata -a -i /dev/sda | grep "User Capacity" >> /home/$USER/Desktop/specs.tex


#detect CD/DVD drive
echo "\section{DVDDrive}" >> /home/$USER/Desktop/specs.tex
cd-drive | grep Vendor >> /home/$USER/Desktop/specs.tex
echo "\quad" >> /home/$USER/Desktop/specs.tex
cd-drive | grep Model >> /home/$USER/Desktop/specs.tex
echo "\quad" >> /home/$USER/Desktop/specs.tex
cd-drive | grep Revision >> /home/$USER/Desktop/specs.tex

#detect network card information
echo "\section{Network}" >> /home/$USER/Desktop/specs.tex
sudo lshw -class network | grep product >> /home/$USER/Desktop/specs.tex

#detect sound card information
echo "\section{Sound}" >> /home/$USER/Desktop/specs.tex
sudo lshw -class sound | grep -m 1 product >> /home/$USER/Desktop/specs.tex

echo "\end{document}" >> /home/$USER/Desktop/specs.tex
cd /home/$USER/Desktop
# the line below strips out any underscores _ from specs.tex
sed -i s/\_//g specs.tex
sed 's/^	*$//g' specs.tex > specifications.tex
pdflatex specifications.tex
