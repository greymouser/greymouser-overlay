# Copyright 2023-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit go-module

DESCRIPTION="What started as the offspring of oh-my-posh2 for PowerShell resulted in a cross platform, highly customizable and extensible prompt theme engine."
HOMEPAGE="https://github.com/JanDeDobbeleer/${PN}"
SRC_URI="
	https://github.com/JanDeDobbeleer/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/greymouser/greymouser-distfiles/raw/refs/heads/main/${P}-deps.tar.xz
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

IUSE=""

S="${WORKDIR}/${P}/src"

src_compile() {
    ego build -v \
	-buildvcs=false \
	-o ${PN} \
	-ldflags "-s -w -X 'github.com/jandedobbeleer/oh-my-posh/src/build.Version=${PV}' -extldflags '-static'"
}

src_install() {
    dobin ${PN}

    pushd "${WORKDIR}/${P}"
	insinto /usr/share/${PN}
	doins -r themes
    popd

    default
}

pkg_postinst() {
	elog "You will need to set up oh-my-posh before use."
	elog "For example, if using bash, add the following to your ~/.bashrc:"
	elog "  eval \"\$(oh-my-posh init bash)\""
	elog "zsh is setup similarly, just replace bash with zsh"
	elog "Check https://ohmyposh.dev/docs/installation/prompt for other shells, like fish"
}
