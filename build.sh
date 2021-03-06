#!/usr/bin/env bash

set -e

FILENAME='bigchaindb-whitepaper.pdf'
FILENAME_PRIMER='bigchaindb-primer.pdf'

# # Either of those would be sooooo great, and would replace this whole file
# #pandoc -o $FILENAME src/index.tex
# #rubber --pdf --texpath=src/img src/index.tex

# check that pdflatex is installed and available
if ! pdflatex_loc="$(type -p "pdflatex")" || [ -z "$pdflatex_loc" ]; then
	echo "FATAL ERROR: pdflatex not available, please check LaTeX installation and environment"
	exit
fi

function pdfs {
    pdflatex -interaction=nonstopmode index.tex
    pdflatex -interaction=nonstopmode addendum.tex
    pdflatex -interaction=nonstopmode primer.tex
}

function pdfs_combine {
	if [[ "$OSTYPE" == "darwin"* ]]; then
		# use Apple's builtin tool
		"/System/Library/Automator/Combine PDF Pages.action/Contents/Resources/join.py" -o $FILENAME index.pdf addendum.pdf
	else
		pdftk index.pdf addendum.pdf cat output $FILENAME
	fi
}

# create or empty the build tmp folder
if ! [ -d "tmp" ]; then
	mkdir tmp
else
	rm -R -f tmp/*
fi

# remove whitepaper in root
rm -R -f $FILENAME

# copy src to build dir and go in
cp src/*.* tmp/
cp -R src/img tmp/
cd tmp

# build, first pass
pdfs

# bibtext the output
bibtex index
bibtex primer

# build, second pass, needed for page numbering
pdfs

# build, third pass, needed for bibliography
pdfs

# check the intermediate PDFs were built and exist
if ! [ -f "index.pdf" ] || ! [ -f "addendum.pdf" ] || ! [ -f "primer.pdf" ]; then
	echo "FATAL ERROR: could not construct PDF files, check tex sources for errors"
	exit
fi

# combine pdflatex output files
pdfs_combine

# check for final pdf file being there
if ! [ -f $FILENAME ]; then
    echo "FATAL ERROR: could not construct final PDF file, check tex sources or pdftk output for errors"
	exit
fi

# copy bigchaindb-whitepaper.pdf to root directory
cp $FILENAME ../$FILENAME

# copy bigchaindb-whitepaper-primer.pdf to root directory
cp primer.pdf ../$FILENAME_PRIMER

echo "PDFs successfully generated. Whoop whoop."

exit
