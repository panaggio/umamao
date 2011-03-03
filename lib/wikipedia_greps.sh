sed -n 's/\s*<title>\(.*\)<\/title>/\1/p' < $1 > tmp/titles.txt &
sed -n 's/\s*<id>\(.*\)<\/id>/\1/p' < $1 > tmp/ids.txt &
sed -n 's/\s*<abstract>\(.*\)<\/abstract>/\1/p' < $2 > tmp/abstracts.txt &
sed -n 's/\s*<url>\(.*\)<\/url>/\1/p' < $2 > tmp/urls.txt &
