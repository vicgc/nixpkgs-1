#!/usr/bin/env bash
set -e

releaseid="${1:?no release id given}"

if ! echo "$releaseid" | egrep -q '^[0-9]{4}_[0-9]{3}$'; then
    echo "$0: release id must be of the form YYYY_NNN" >&2
    exit 64
fi

echo "$0: performing release"
dev="fc-15.09-dev"
stag="fc-15.09-staging"
prod="fc-15.09-production"

git remote update -p

git checkout $stag
git merge --ff-only
git checkout $prod
git merge --ff-only
msg="Merge branch '$stag' into $prod for release $releaseid"
git merge --no-ff -m "$msg" $stag

git tag -a -m "Release r$releaseid" "fc/r$releaseid"

git checkout $dev
git merge --ff-only
msg="Backmerge branch '$prod' into $dev for release $releaseid"
git merge --no-ff -m "$msg" $prod

echo "$0: created changes:"
git log -n 2 --decorate --stat
echo "$0: issue 'git push origin $dev $stag $prod' if this looks correct"
