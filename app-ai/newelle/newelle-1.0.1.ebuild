# Copyright 2023-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{13..14} )
inherit meson edo flag-o-matic xdg

PN="${PN/n/N}"
P="${PN}-${PV}"
S="${WORKDIR}/${P}"
DESCRIPTION="Newelle - Your Ultimate Virtual Assistant"
HOMEPAGE="https://github.com/qwersyk/${PN}"
#SRC_URI="https://github.com/anufrievroman/${PN}/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"
SRC_URI="https://github.com/greymouser/greymouser-distfiles/raw/refs/heads/main/${P}.tar.xz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

IUSE=""
REQUIRED_USE="
        ${PYTHON_REQUIRED_USE}
"
RDEPEND="
        ${PYTHON_DEPS}
	dev-python/gtts
        dev-python/speech_recognition
"
DEPEND="
	${RDEPEND}
	gui-libs/gtksourceview
"
BDEPEND="
        ${PYTHON_DEPS}
"

DOCS=( README.md )

src_install() { 
  meson_install
  chmod +x "${D}/usr/bin/newelle"
}
