# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PIPER_VOICES_COMMIT="b23e00315cccfa7360b3a7f89b95da786efc4656"

## if PIPER_VOICES_COMMIT is empty, setup SRC_URI, else SETUP HF_* variables
if [[ -z "${PIPER_VOICES_COMMIT}" ]]; then
    # NOTE: This can't really work, since fetch/digest/manifest isn't overridable
    #SRC_URI="
    #    hf+repo:model:rhasspy/${PN}@${PIPER_VOICES_COMMIT} -> ${PN}-${PIPER_VOICES_COMMIT}.tar.gz
    #"
    einfo "No SRC_URI for this ebuild"
else
    HF_REPO_ID="rhasspy/${PN}"
    HF_REPO_TYPE="model"
    HF_REV="${PIPER_VOICES_COMMIT}"
    # Optional: space/comma separated patterns to skip
    #HF_IGNORE="*.bin *.fp16.safetensors"
    HF_DEST="${PN}-${HF_REV}"   # default is a directory under ${WORKDIR}/huggingface
fi

PYTHON_COMPAT=( python3_{13..14} )
inherit python-any-r1 huggingface-r1

DESCRIPTION="Voices for Piper text to speech system."
HOMEPAGE="https://huggingface.co/rhasspy/${PN}"

S="${WORKDIR}/${PN}-${PIPER_VOICES_COMMIT}/huggingface/rhasspy__${PN}-${PIPER_VOICES_COMMIT:0:12}"

LICENSE="MIT GPL-3"
SLOT="0"
KEYWORDS="~amd64"
# IUSE+=""

RDEPEND="
    media-sound/piper
"
DEPEND="${RDEPEND}"
BDEPEND="
    ${HUGGINGFACE_BDEPEND}
"

# src_fetch() {
#   huggingface-r1_src_fetch     # creates ${DISTDIR}/whisper.spm and ${DISTDIR}/piper-voices-b23e.tar.gz
#   default                   # fetch non-HF URIs as usual
# }

# src_unpack() {
#   default                   # unpacks from ${DISTDIR}
# }
