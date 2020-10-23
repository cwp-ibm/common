#!/bin/bash
DEFAULT_OS=ubuntu
DEFAULT_OS_VERSION=20.04

MALWARE=$1
OS=${2:-${DEFAULT_OS}}
OS_VERSION=${3:-$DEFAULT_OS_VERSION}

IMAGE_TAG="${MALWARE}":"${OS}"_"${OS_VERSION}"

docker build --build-arg OS="${OS}" --build-arg VERSION="${OS_VERSION}" --build-arg EXECUTABLE="${MALWARE}" --tag "${IMAGE_TAG}" .