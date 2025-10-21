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

DESCRIPTION="Elevate is a small Python library that re-launches the current process with root/admin privileges"
HOMEPAGE="https://pypi.org/project/${PN}/"
SRC_URI="https://files.pythonhosted.org/packages/81/32/29ba61063ac124632754e26c65e71217f48ce682fbf8762ee9a0bb0d32de/${P}.tar.gz"
LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

IUSE=""
REQUIRED_USE="
        ${PYTHON_REQUIRED_USE}
"

RDEPEND="
        ${PYTHON_DEPS}
"
DEPEND="
	${RDEPEND}
"
BDEPEND="
        ${PYTHON_DEPS}
"

DOCS=( README.rst )

#src_compile() {
#	edo "${EPYTHON}" setup.py build
#}
#
#src_install() {
#	edo "${EPYTHON}" setup.py install
#}
