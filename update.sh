#!/bin/bash
set -e

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( 5*/ )
fi
versions=( "${versions[@]%/}" )

packagesUrl='http://repo.percona.com/apt/dists/trusty/main/binary-amd64/Packages'
packages="$(echo "$packagesUrl" | sed -r 's/[^a-zA-Z.-]+/-/g')"
curl -sSL "${packagesUrl}.gz" | gunzip > "$packages"

for version in "${versions[@]}"; do
	cp start_pxc.sh "$version/start_pxc.sh"
	cp -Tr templates "$version/templates"
	cp -Tr conf.d "$version/conf.d"

	echo $version

	fullVersion="$(grep -m1 -A10 "^Package: percona-xtradb-cluster-$version\$" "$packages" | grep -m1 '^Version: ' | cut -d' ' -f2)"
	(
		set -x
		sed '
			s/%%PERCONA_MAJOR%%/'"$version"'/g;
			s/%%PERCONA_VERSION%%/'"$fullVersion"'/g;
		' Dockerfile.template > "$version/Dockerfile"
	)
done

rm "$packages"
