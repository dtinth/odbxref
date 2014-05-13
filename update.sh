set -e
archive() {
  rm -fv cache/index-$1-$2.cache
  echo 'Adding to index:' $1-$2
  ruby odbxref.rb archive $1 $2
}
archive `date -v-1m +'%Y %m'`
archive `date +'%Y %m'`
ruby odbxref.rb chapters
git commit -am "Update index for `date +'%Y-%m-%d'`"
