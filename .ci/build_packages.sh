#!/usr/bin/env bash
set -e

base_image="ghcr.io/firezone/${MATRIX_IMAGE}"
tag=release-${MATRIX_IMAGE}

case $MATRIX_IMAGE in
  amazonlinux*)
    format="rpm"
    ;;
  centos*)
    format="rpm"
    ;;
  fedora*)
    format="rpm"
    ;;
  debian*)
    format="deb"
    ;;
  ubuntu*)
    format="deb"
    ;;
esac


# Build intermediate release image
docker buildx build \
  -f pkg/Dockerfile.release \
  -t $tag \
  --platform linux/amd64 \
  --build-arg BASE_IMAGE=$base_image \
  --progress plain \
  .



case $format in
  deb)
    pkg_dir="${MATRIX_IMAGE/:/_}_amd64"
    pkg_file="${pkg_dir}.deb"
    image="${pkg_dir}:latest"

    docker buildx build \
      -t $image \
      -f pkg/Dockerfile.deb \
      --platform linux/amd64 \
      --build-arg PKG_DIR=$pkg_dir \
      --build-arg BASE_IMAGE=$tag \
      --progress plain \
      .

    cid=$(docker create $image)
    mkdir -p _build
    docker cp $cid:/root/pkg/$pkg_file ./_build/firezone_$pkg_file
    ;;

  rpm)
    version=0.2.0-1
    pkg_dir="firezone-${version}.amd64"
    pkg_file="${pkg_dir}.rpm"
    image="${MATRIX_IMAGE/:/_}_amd64:latest"

    docker buildx build \
      -t $image \
      -f pkg/Dockerfile.rpm \
      --platform linux/amd64 \
      --build-arg PKG_DIR=$pkg_dir \
      --build-arg BASE_IMAGE=$tag \
      --progress plain \
      .

    cid=$(docker create $image)
    mkdir -p _build
    docker cp $cid:/root/rpmbuild/RPMS/amd64/$pkg_file ./_build/$pkg_file
    ;;
esac