# Copyright 2023-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit go-module

DESCRIPTION="A tool for glamorous shell scripts. Leverage the power of Bubbles and Lip Gloss in your scripts and aliases without writing any Go code!"
HOMEPAGE="https://github.com/charmbracelet/gum"
SRC_URI="
	https://github.com/charmbracelet/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/greymouser/greymouser-distfiles/raw/refs/heads/main/${P}-deps.tar.xz
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

IUSE=""

S="${WORKDIR}/${P}"

src_compile() {
    ego build -v \
	-buildvcs=false \
	-o ${PN}
}

src_install() {
    dobin ${PN}

    default
}
