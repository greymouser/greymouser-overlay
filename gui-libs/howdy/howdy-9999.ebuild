# Copyright 2023-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson toolchain-funcs flag-o-matic

DESCRIPTION="Howdy provides Windows Hello™ style authentication for Linux. Use your built-in IR emitters and camera in combination with facial recognition to prove who you are."
HOMEPAGE="https://github.com/boltgolt/howdy"

# In case this is a real snapshot, fill in commit below.
# For normal, tagged releases, leave blank
MY_COMMIT="d3ab99382f88f043d15f15c1450ab69433892a1c"

if [[ "${PV}" = *9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/boltgolt/${PN^}.git"
else
	if [[ -n "" ]]; then
		SRC_URI="https://github.com/boltgolt/${PN^}/releases/download/v${PV}/source-v${PV}.tar.gz -> ${P}.gh.tar.gz"
		S="${WORKDIR}/${PN}-${MY_COMMIT}"
	else
		SRC_URI="https://github.com/boltgolt/${PN^}/releases/download/v${PV}/source-v${PV}.tar.gz -> ${P}.gh.tar.gz"
	fi

	KEYWORDS="~amd64"
fi

LICENSE="MIT"
SLOT="0"
IUSE="X +qtutils systemd"

# hyprpm (hyprland plugin manager) requires the dependencies at runtime
# so that it can clone, compile and install plugins.
HYPRPM_RDEPEND="
	app-alternatives/ninja
	>=dev-build/cmake-3.30
	dev-build/meson
	dev-vcs/git
	virtual/pkgconfig
"
RDEPEND="
	${HYPRPM_RDEPEND}
	dev-cpp/tomlplusplus
	dev-libs/glib:2
	>=dev-libs/hyprlang-0.3.2
	dev-libs/libinput:=
	>=dev-libs/hyprgraphics-0.1.3:=
	dev-libs/re2:=
	>=dev-libs/udis86-1.7.2
	>=dev-libs/wayland-1.22.90
	>=gui-libs/aquamarine-0.9.0:=
	>=gui-libs/hyprcursor-0.1.9
	>=gui-libs/hyprutils-0.8.2:=
	media-libs/libglvnd
	media-libs/mesa
	sys-apps/util-linux
	x11-libs/cairo
	x11-libs/libdrm
	x11-libs/libxkbcommon
	x11-libs/pango
	x11-libs/pixman
	x11-libs/libXcursor
	qtutils? ( gui-libs/hyprland-qtutils )
	X? (
		x11-libs/libxcb:0=
		x11-base/xwayland
		x11-libs/xcb-util-errors
		x11-libs/xcb-util-wm
	)
"
DEPEND="
	${RDEPEND}
	dev-cpp/glaze
	>=dev-libs/hyprland-protocols-0.6.4
	>=dev-libs/wayland-protocols-1.45
"
BDEPEND="
	|| ( >=sys-devel/gcc-15:* >=llvm-core/clang-19:* )
	app-misc/jq
	dev-build/cmake
	>=dev-util/hyprwayland-scanner-0.4.5
	virtual/pkgconfig
"

PATCHES=(
	"${FILESDIR}"/clean-startup.patch
	"${FILESDIR}"/scroll-finger.patch
)

pkg_setup() {
	[[ ${MERGE_TYPE} == binary ]] && return

	if tc-is-gcc && ver_test $(gcc-version) -lt 15 ; then
		eerror "Hyprland requires >=sys-devel/gcc-15 to build"
		eerror "Please upgrade GCC: emerge -v1 sys-devel/gcc"
		die "GCC version is too old to compile Hyprland!"
	elif tc-is-clang && ver_test $(clang-version) -lt 19 ; then
		eerror "Hyprland requires >=llvm-core/clang-19 to build"
		eerror "Please upgrade Clang: emerge -v1 llvm-core/clang"
		die "Clang version is too old to compile Hyprland!"
	fi
}

src_prepare() {
	# skip version.h
	sed -i -e "s|scripts/generateVersion.sh|echo|g" meson.build || die
	default
}

src_configure() {
	append-cflags '-DDEBUGLEVEL=0'
	append-cxxflags '-DDEBUGLEVEL=0'
	local emesonargs=(
		$(meson_feature systemd)
		$(meson_feature X xwayland)
	)
	meson_src_configure
}

