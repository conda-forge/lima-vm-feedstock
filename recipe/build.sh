#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

mkdir -p ${PREFIX}/bin
mkdir -p ${PREFIX}/share

# Add missing --force to codesign call on macOS
sed -i "s/codesign -f -v/codesign -f/" Makefile

make VERSION=${PKG_VERSION} CC=${CC} binaries
cp -r _output/bin/* ${PREFIX}/bin
cp -r _output/share/* ${PREFIX}/share

if [[ ${target_platform} == ${build_platform} ]]; then
    make VERSION=${PKG_VERSION} manpages
    mkdir -p ${PREFIX}/etc/bash_completion.d
    mkdir -p ${PREFIX}/share/zsh/site-functions
    mkdir -p ${PREFIX}/share/fish/vendor_completions.d
    limactl completion bash > ${PREFIX}/etc/bash_completion.d/lima
    limactl completion zsh > ${PREFIX}/share/zsh/site-functions/_lima
    limactl completion fish > ${PREFIX}/share/fish/vendor_completions.d/lima.fish
fi

go-licenses save ./cmd/limactl --save_path=license-files
