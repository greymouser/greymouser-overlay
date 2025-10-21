# Copyright 2023-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

#DISTUTILS_EXT=1
#DISTUTILS_OPTIONAL=1
DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..14} )
#inherit edo go-env optfeature multiprocessing python-single-r1
#inherit shell-completion toolchain-funcs xdg
inherit distutils-r1 edo flag-o-matic xdg

MY_PN="gTTS"
DESCRIPTION="gTTS (Google Text-to-Speech), a Python library and CLI tool to interface with Google Translate text-to-speech API"
HOMEPAGE="https://pypi.org/project/${MY_PN}/"
SRC_URI="https://github.com/pndurette/${MY_PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

IUSE=""
REQUIRED_USE="
        ${PYTHON_REQUIRED_USE}
"
S="${WORKDIR}/${MY_PN}-${PV}"

RDEPEND="
        ${PYTHON_DEPS}
"
DEPEND="
	${RDEPEND}
"
BDEPEND="
        ${PYTHON_DEPS}
"

DOCS=( README.md )

#src_compile() {
#	edo "${EPYTHON}" setup.py build
#}
#
#src_install() {
#	edo "${EPYTHON}" setup.py install
#}
