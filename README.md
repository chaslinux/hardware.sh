# hardware.sh
Copyright 2022 Charles McColm <chaslinux@gmail.com>

This and all files are licensed under GPLv3, the GNU General Public License v3.0.

Script to for Ubuntu-based desktop Linux distributions to detect hardware on computers and output it to a PDF using latex.

This script assumes a typical desktop install of Ubuntu/Kubuntu/Xubuntu/Lubuntu/Ubuntu Mate/Ubuntu Budgie. It's been tested on a few
Xubuntu systems as of January 6, 2022.

Run the script by typing the next line in a terminal:
./hardware.sh

You will be prompted for your password (assumes you are the first user with sudo access).

This script installs the following programs and their dependencies to help with hardware detection and the creation of a PDF file:

smartmontools
libcdio-utils
texlive-latex-base

Four files are created on the current user's desktop:

specs.tex - this is the LaTeX file with information about the system
specs.log - parsing log information when pdflatex creates specs.pdf from specs.tex
specs.aux - aux files are typesetting info for LaTeX
specs.pdf - This is the file you want to print / attach to the system you're making available

If you use this script for your computer refurbishing project please drop me an email to let me know it's been helpful.

