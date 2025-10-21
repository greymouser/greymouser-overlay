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

DESCRIPTION="GUI wallpaper setter for Wayland and Xorg window managers"
HOMEPAGE="https://github.com/anufrievroman/${PN}"
SRC_URI="https://github.com/anufrievroman/${PN}/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

IUSE="+X wayland"
REQUIRED_USE="
        ${PYTHON_REQUIRED_USE}
"

RDEPEND="
        ${PYTHON_DEPS}
	gui-apps/mpvpaper
	dev-python/imageio
	dev-python/imageio-ffmpeg
	dev-python/platformdirs
	dev-python/screeninfo
	X? (
		x11-libs/libX11
		media-gfx/feh
	)
	wayland? ( dev-libs/wayland )
"
DEPEND="
	${RDEPEND}
        X? (
                x11-base/xorg-proto
                x11-libs/libXi
                x11-libs/libXinerama
                x11-libs/libXrandr
        )
        wayland? ( dev-libs/wayland-protocols )
"
BDEPEND="
        ${PYTHON_DEPS}
        wayland? ( dev-util/wayland-scanner )
"

DOCS=( README.md )

#src_compile() {
#	edo "${EPYTHON}" setup.py build
#}
#
#src_install() {
#	edo "${EPYTHON}" setup.py install
#}
