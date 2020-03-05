# --- flag defaults ---
clean="no"
verbose="no"

sitemap_head='<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
sitemap_tail='</urlset>'
sitemapindex_head='<?xml version="1.0" encoding="UTF-8"?><sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
sitemapindex_tail='</sitemapindex>'
time=$(date +%Y-%m-%d)
sitemap_file_index=1
url_index=1

for arg in "$@"
do
    case $arg in
        -v|--verbose)
            verbose="yes"
            ;;
        --clean)
            clean="yes"
            ;;
        --config=*)
            config=$(echo "$arg" | sed -e "s/--config=//")
            . ./$config
            ;;
    esac
done

# --- configurables ---
max_sitemap_size=${max_sitemap_size:-49000}
sitemap_filepath=${sitemap_filepath:-"https://example.com/"}
sitemap_prefix=${sitemap_prefix:-"sitemap-"}
sitemapindex_filename=${sitemapindex_filename:-"sitemap.xml"}
url_source_filename=${url_source_filename:-"sitemap.csv"}
#line_count=$(wc -l $url_source_filename | awk "{ print $1 }")
line_count=3655356
single_digit_batch=$(find . -name 'batch-[0-9].*' | sort -n)
double_digit_batch=$(find . -name 'batch-[0-9][0-9].*' | sort -n)
batch_files=("${single_digit_batch[@]}" "${double_digit_batch[@]}")
sitemap_filename="${sitemap_prefix}${sitemap_file_index}.xml"

if [[ ${verbose} = "yes" ]]; then
    echo "Max sitemap file size: $max_sitemap_size urls"
    echo "Sitemap filepath: $sitemap_filepath"
    echo "Sitemap file prefix: $sitemap_prefix"
    echo "Sitemapindex filename: $sitemapindex_filename"
    echo "Url list source filename: $url_source_filename"
fi

format_sitemap_entry () {
    echo "<url><loc>$1</loc><lastmod>$time</lastmod></url>"
}

format_sitemapindex_entry () {
    echo "<sitemap><loc>$sitemap_filepath$1</loc></sitemap>"
}

init_sitemap () {
    filename=$1
    touch $filename
    echo $sitemap_head >> $filename
    if [[ ${verbose} = "yes" ]]; then
        echo "Sitemap created: $filename"
    fi
}
 
init_sitemapindex () {
    filename=$1
    touch $filename
    echo $sitemapindex_head >> $filename
    if [[ ${verbose} = "yes" ]]; then
        echo "Sitemapindex created: $filename"
    fi
}

add_sitemap_entry () {
    destination_filename=$1
    source_filename=$2
    line_index=$3
    line=$(sed "${line_index}q;d" $source_filename)
    sitemap_entry=$(format_sitemap_entry $line)
    if [[ ${verbose} = "yes" ]]; then
        echo -ne "Line[$line_index]: $sitemap_entry"\\r
    fi
    echo $sitemap_entry >> $destination_filename
}

add_sitemapindex_entry () {
    index_filename=$1
    entry_filename=$2
    sitemapindex_entry=$(format_sitemapindex_entry $entry_filename)
    if [[ ${verbose} = "yes" ]]; then
        echo "Add to sitemap index: $entry_filename"
    fi
    echo $sitemapindex_entry >> $index_filename
}

init_sitemapindex $sitemapindex_filename

for batch_file in $batch_files
do
    sitemap_filename="$sitemap_prefix${sitemap_file_index}.xml"
    init_sitemap $sitemap_filename
    add_sitemapindex_entry $sitemapindex_filename $sitemap_filename
    batch_file_line_count=$(wc -l $batch_file | awk '{ print $1 }')
    url_index=1
    while [ $url_index -le $batch_file_line_count ]
    do
        add_sitemap_entry $sitemap_filename $batch_file $url_index
        ((url_index++))
    done
    echo $sitemap_tail >> $sitemap_filename
    exit
done

echo $sitemapindex_tail >> $sitemapindex_filename

if [[ ${clean} = "yes" ]]; then
    rm $sitemapindex_filename $sitemap_prefix*
fi
