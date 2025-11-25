#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

mkdir -p ${PREFIX}/bin
mkdir -p ${PREFIX}/share

# Delete incorrect codesign binary from BUILD_PREFIX so host provided one is used instead
rm -rf ${BUILD_PREFIX}/bin/codesign
ln -sf /usr/bin/codesign ${BUILD_PREFIX}/bin/codesign

# Remove buildmode=pie because it doesn't work here
export GOFLAGS=${GOFLAGS/-buildmode=pie/}

make VERSION=${PKG_VERSION} CC=${CC} binaries
cp -r _output/bin/* ${PREFIX}/bin
cp -r _output/share/* ${PREFIX}/share

if [[ ${target_platform} == ${build_platform} ]]; then
    make VERSION=${PKG_VERSION} CC=${CC} manpages
    mkdir -p ${PREFIX}/etc/bash_completion.d
    mkdir -p ${PREFIX}/share/zsh/site-functions
    mkdir -p ${PREFIX}/share/fish/vendor_completions.d
    limactl completion bash > ${PREFIX}/etc/bash_completion.d/lima
    limactl completion zsh > ${PREFIX}/share/zsh/site-functions/_lima
    limactl completion fish > ${PREFIX}/share/fish/vendor_completions.d/lima.fish
fi

go-licenses save ./cmd/limactl --save_path=license-files
