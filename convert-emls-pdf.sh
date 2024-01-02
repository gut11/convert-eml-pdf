#!/usr/bin/env bash

# For this script to work it's necessary to have mhonarc and pandoc and the weasyprint pdf engine

pdf_engine="weasyprint"
temp_dir=""
input_dir="$1"
nothread="-nothread"

function get_input_dir {
	if [ "$#" -gt 2 ] || [ $# -lt 1 ]; then
		echo "Usage: $0 <folder>"
		exit 1
	fi
	echo $input_dir
	if [ ! -d "$input_dir" ]; then
		echo "Error: The specified folder does not exist."
		exit 1
	fi
}

function search_nothread_argument {
    if [[ "$*" == *"-nothread"* ]]; then
        nothread="-nothread"
    else
        nothread=""
    fi
}

function check_installed {
	command -v mhonarc >/dev/null 2>&1 || { echo >&2 "mhonarc is not installed. Aborting."; exit 1; }
	command -v pandoc >/dev/null 2>&1 || { echo >&2 "pandoc is not installed. Aborting."; exit 1; }
}

function create_dirs {
	temp_dir=$(mktemp -d)
	mkdir -p pdfs
}

function convert_links_from_html_to_pdf {
	find "$temp_dir" -type f -name '*.html' -exec sed 's/<\([^h]*\)href="\([^.]*\).html/<\1href="\2.pdf/g' -i {} \;
}

function remove_newlines {
	find $temp_dir -type f -name "*.html" -exec sh -c 'tr -d "\n" < {} > ./temp.html && mv ./temp.html {}' \;
}

function convert_to_relative_links {
	find "./pdfs/" -type f -name '*.pdf' -exec sed 's/URI (file:.*\/\(.*\)\.pdf/URI (\1.pdf/gp' -i {} \; 
}

function convert_to_pdf {
	remove_newlines
	convert_links_from_html_to_pdf
	find $temp_dir -type f -name '*.html' -exec sh -c 'filename={}; pandoc --pdf-engine='$pdf_engine' --pdf-engine-opt=-q $filename -o pdfs/$(basename "$filename" .html).pdf ' \;
}

function convert_to_html {
	find $input_dir -type f -name "*.eml" -exec mhonarc -add {} "-nodoc" $nothread -outdir $temp_dir \; 
}

function convert_files {
	convert_to_html
	convert_to_pdf
	convert_to_relative_links
}

function move_attachments {
	find $temp_dir -type f ! -name 'mailist*' ! -name 'msg*' ! -name 'threads*' -exec mv {} "./pdfs" \;
}

function remove_temp_dir {
	rm -rf $temp_dir
}

function finish_script {
	move_attachments
	remove_temp_dir
	echo "Conversion completed. PDF files are saved in a ./pdfs directory."
}

check_installed
get_input_dir $@
search_nothread_argument $@
create_dirs
convert_files
finish_script
