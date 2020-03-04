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
line_count=$(wc -l $url_source_filename | awk "{ print $1 }")
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
    url=$(sed "${url_index}q;d" $url_source_filename)
    sitemap_entry=$(format_sitemap_entry $url)
    if [[ ${verbose} = "yes" ]]; then
        echo "Line[$url_index]: $sitemap_entry"
    fi
    echo $sitemap_entry >> $sitemap_filename
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

if [[ ${verbose} = "yes" ]]; then
    echo "Line count: $line_count"
fi

init_sitemapindex $sitemapindex_filename
init_sitemap $sitemap_filename
add_sitemapindex_entry $sitemapindex_filename $sitemap_filename

while [ $url_index -le $line_count ]
do
    if !(( $url_index % $max_sitemap_size )); then
        echo $sitemap_tail >> $sitemap_filename
        ((sitemap_file_index++))
        sitemap_filename="$sitemap_prefix${sitemap_file_index}.xml"
        init_sitemap $sitemap_filename
        add_sitemapindex_entry $sitemapindex_filename $sitemap_filename
    fi
    add_sitemap_entry $sitemap_filename $url_index
    ((url_index++))
done

echo $sitemap_tail >> $sitemap_filename
echo $sitemapindex_tail >> $sitemapindex_filename

if [[ ${clean} = "yes" ]]; then
    rm $sitemapindex_filename $sitemap_prefix*
fi
