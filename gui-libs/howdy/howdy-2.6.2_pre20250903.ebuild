# Copyright 2023-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson toolchain-funcs flag-o-matic pam

DESCRIPTION="Howdy provides Windows Hello™ style authentication for Linux. Use your built-in IR emitters and camera in combination with facial recognition to prove who you are."
HOMEPAGE="https://github.com/boltgolt/howdy"

# In case this is a real snapshot, fill in commit below.
# For normal, tagged releases, leave blank
MY_COMMIT="d3ab99382f88f043d15f15c1450ab69433892a1c"

if [[ "${PV}" = *9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/boltgolt/${PN}.git"
else
	if [[ -n "${MY_COMMIT}" ]]; then
		SRC_URI="https://github.com/boltgolt/${PN}/archive/${MY_COMMIT}.tar.gz -> ${P}.tar.gz"
		S="${WORKDIR}/${PN}-${MY_COMMIT}"
	else
		SRC_URI="https://github.com/boltgolt/${PN}/releases/download/v${PV}/source-v${PV}.tar.gz -> ${P}.gh.tar.gz"
	fi

	KEYWORDS="~amd64"
fi

LICENSE="MIT CC0-1.0"
SLOT="0"
IUSE="policykit"

RDEPEND="
	>=sci-libs/dlib-20.0.0[models]
	dev-python/elevate
	media-libs/opencv[python]
"
DEPEND="
	${RDEPEND}
"
BDEPEND="
	${DEPEND}
	app-alternatives/ninja
	>=dev-build/cmake-3.30
	dev-build/meson
	dev-vcs/git
	virtual/pkgconfig
"

src_configure() {
	local emesonargs=(
		-Dinstall_pam_config=true
		-Dinstall_pam_config=true
		-Ddlib_data_dir="/usr/share/dlib-models"
		$(meson_use policykit with_polkit)
	)
	meson_src_configure
}

