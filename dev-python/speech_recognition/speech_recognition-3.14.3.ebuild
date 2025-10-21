# Copyright 2023-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..14} )
inherit distutils-r1 edo flag-o-matic xdg

MY_P="SpeechRecognition"
DESCRIPTION="Library for performing speech recognition, with support for several engines and APIs, online and offline."
HOMEPAGE="https://pypi.org/project/${MY_P}/"
SRC_URI="https://github.com/Uberi/${PN}/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"
LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

PATCHES=(
        "${FILESDIR}/build-fix.patch"
)

IUSE=""
REQUIRED_USE="
        ${PYTHON_REQUIRED_USE}
"

RDEPEND="
        ${PYTHON_DEPS}
        dev-python/standard-aifc
"
DEPEND="
	${RDEPEND}
"
BDEPEND="
        ${PYTHON_DEPS}
"

DOCS=( README.rst )
