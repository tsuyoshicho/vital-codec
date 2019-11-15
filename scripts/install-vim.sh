#!/bin/bash

set -ev

if [[ "${VIM_VERSION}" == "" ]]; then
	exit
fi
git clone --depth 1 --branch "${VIM_VERSION}" https://github.com/vim/vim ${GITHUB_WORKSPACE}/vim-tmp
cd ${GITHUB_WORKSPACE}/vim-tmp
./configure --prefix="${GITHUB_WORKSPACE}/vim" --with-features=huge --enable-pythoninterp \
	--enable-python3interp --enable-fail-if-missing
	make -j2
	make install
