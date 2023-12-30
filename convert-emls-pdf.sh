#!/usr/bin/env bash

# For this script to work it's necessary to have mhonarc and pandoc and the weasyprint pdf engine

pdf_engine="weasyprint"
temp_folder=""
input_folder="$1"
nothread=""

function get_input_dir {
	if [ "$#" -gt 2 ] || [$# -lt 1]; then
		echo "Usage: $0 <folder>"
		exit 1
	fi
	echo $input_folder
	if [ ! -d "$input_folder" ]; then
		echo "Error: The specified folder does not exist."
		exit 1
	fi
}

function search_nothread {
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
	temp_folder=$(mktemp -d)
	mkdir -p pdfs
}

function fix_html_links {
	find "$temp_folder" -type f -name '*.html' -exec sed '/\(<.*href="\(.*\).html".*>\)/ s/href="\(.*\).html"/href="\1.pdf"/' -i {} \;
}

function convert_to_relative_links {
	find -type f -name '*.pdf' -exec sed 's/\/URI (file:\/\/\/.*\/\(.*\.pdf\))/\/URI (.\/\1)/g' -i {} \; 
}

function convert_files {
	find "$input_folder" -type f -name '*.eml' -exec mhonarc $nothread -outdir "$temp_folder" {} \;
	fix_html_links
	find "$temp_folder" -type f -name '*.html' -exec sh -c 'filename={}; pandoc --pdf-engine='$pdf_engine' $filename -o pdfs/$(basename "$filename" .html).pdf ' \;
	convert_to_relative_links
}

function finish_script {
	rm -rf $temp_folder
	echo "Conversion completed. PDF files are saved in a pdfs directory."
}

check_installed
get_input_dir $@
search_nothread $@
create_dirs
convert_files
finish_script
