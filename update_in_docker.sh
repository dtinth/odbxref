
set -e
echo -n "Start: "
date
cd "`dirname "$0"`"
docker run --rm -v "$(pwd):/odbxref" odbxref bash -c 'cd odbxref && git config --global user.name "odbxref Bot" && git config --global user.email "odbxref@dt.in.th" && bash update.sh'
git push
