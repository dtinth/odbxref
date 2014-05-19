set -e
ruby -v
archive() {
  rm -fv cache/index-$1-$2.cache
  echo 'Adding to index:' $1-$2
  ruby odbxref.rb archive $1 $2 --trace
}
if date -v-1m >/dev/null 2>&1; then
	LAST_MONTH=`date -v-1m +'%Y %m'`
else
	LAST_MONTH=`date --date="last month" +'%Y %m'`
fi
archive $LAST_MONTH
archive `date +'%Y %m'`
ruby odbxref.rb chapters
git add -A
git commit -m "$(cat commit.msg)"
