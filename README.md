![specsheet](https://github.com/chaslinux/hardware.sh/assets/97259120/dbe65ec3-b93d-4c59-9a7b-51e1db569c8e)

# hardware.sh
Copyright 2022 Charles McColm <chaslinux@gmail.com>, 
with thanks to Alan Pope: https://github.com/popey and Greg Korodi https://github.com/korger for many improvements.

This and all files are licensed under GPLv3, the GNU General Public License v3.0.

Script to for Ubuntu-based desktop Linux distributions to detect hardware on computers and output it to a PDF using latex.

This script assumes a typical desktop install of Ubuntu or an Ubuntu derivative (like Linux Mint). It's been tested on dozens of systems 
running Xubuntu and Linux Mint.

Run the script by typing the next line in a terminal:
./hardware.sh

You will be prompted for your password (assumes you are the first user with sudo access).

This script installs the following programs and their dependencies to help with hardware detection and the creation of a PDF file:

smartmontools
libcdio-utils
acpi
barcode
texlive-latex-base
texlive-extra-utils
texlive-pictures

Several files are created on the current user's desktop during the process:

specs.tex - this is the LaTeX file with information about the system
specs.log - parsing log information when pdflatex creates specs.pdf from specs.tex
specs.aux - aux files are typesetting info for LaTeX
barcode.txt - This is the system serial number, the textfile is used briefly then auto deleted by the script
barcode.eps - This is the image of the serial number in EPS (Encapsulated Postscript format), it's auto deleted
barcode.pdf - This is the same as above, but in PDF format so it can be cropped, it's auto deleted after use
serial.pdf - This is a cropped version of the barcode.pdf which is inserted into specs.tex, it is deleted after 
specs.tex is outputted to specs.pdf
specs.pdf - This is the file you want to print / attach to the system you're making available

Most of the files above are deleted during the process of the script. If the script doesn't finish you may see a
LaTeX prompt. You can exit the LaTeX prompt with an X. If you run into bugs, please drop me an email.

If you use this script for your computer refurbishing project please drop me an email to let me know it's been helpful.
