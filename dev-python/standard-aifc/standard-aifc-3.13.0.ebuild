# Copyright 2023-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

#DISTUTILS_EXT=1
#DISTUTILS_OPTIONAL=1
DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{13..14} )
#inherit edo go-env optfeature multiprocessing python-single-r1
#inherit shell-completion toolchain-funcs xdg
inherit distutils-r1

MY_P="SpeechRecognition"
DESCRIPTION="If your project depends on a module that has been removed from the standard, here is the redistribution of the dead batteries in pure Python."
HOMEPAGE="https://github.com/youknowone/python-deadlib"
SRC_URI="https://github.com/youknowone/python-deadlib/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

# MY_MODULES="aifc asynchat asyncore cgi cgitb chunk crypt imghdr mailcap nntplib pipes smtpd sndhdr sunau telnetlib template uu"
# IUSE="-${MY_MODULES// / -}"

S="${WORKDIR}/python-deadlib-${PV}/${PN#*-}"

REQUIRED_USE="
        ${PYTHON_REQUIRED_USE}
"
RDEPEND="
        ${PYTHON_DEPS}
        dev-python/standard-chunk
        dev-python/audioop-lts
"
DEPEND="
	${RDEPEND}
"
BDEPEND="
        ${PYTHON_DEPS}
"

# src_install() {
#         for d in ${MY_MODULES}; do
#                 if use "${d}"; then
#                         pushd "${d}"
#                                 distutils-r1_python_install "standard-${d}"
#                         popd
#                 fi
#         done
# }
