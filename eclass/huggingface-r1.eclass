# @ECLASS: huggingface-r1.eclass
# @MAINTAINER:
#   Armando DiCianno armando@dicianno.org
# @AUTHOR:
#   Armando DiCianno armando@dicianno.org
# @BLURB: Download files or repo snapshots from Hugging Face via huggingface_hub using SRC_URI entries.
# @DESCRIPTION:
#   This eclass enables ebuilds to fetch single files or entire repository snapshots from
#   Hugging Face (models, datasets, spaces) using the official huggingface_hub Python
#   library, driven directly by special entries embedded in SRC_URI.
#
#   Supported SRC_URI kinds:
#
#   1) Single file:
#      hf+file:<type>:<repo_id>[@<rev>]?path=<path/in/repo> -> <dest-filename>
#
#   2) Entire repo snapshot at a revision:
#      hf+repo:<type>:<repo_id>[@<rev>][?ignore=<glob1,glob2>] -> <dest-tar.{tar,tar.gz,tar.xz}>
#
#   Authentication:
#     - Use env var HUGGINGFACE_TOKEN or HF_TOKEN for private/gated artifacts.
#
#   Typical ebuild usage (git-r3 style, recommended):
#     EAPI=8
#     inherit python-any-r1 huggingface-r1
#     PROPERTIES="live"
#     BDEPEND="${HUGGINGFACE_BDEPEND}"
#     HF_REPO_ID="rhasspy/piper-voices"
#     HF_REPO_TYPE="model"
#     HF_REV="b23e00315cccfa7360b3a7f89b95da786efc4656"
#     HF_DEST="piper-voices-${HF_REV}"
#     S="${WORKDIR}/huggingface/${HF_DEST}"
#
#   Optional knobs:
#     HUGGINGFACE_CACHE_DIR   - override cache dir (default: ${T}/huggingface-cache)
#     HUGGINGFACE_OFFLINE=1   - force cache-only
#     HUGGINGFACE_TOKEN=...   - auth token (or set HF_TOKEN)
#     HUGGINGFACE_VERBOSE=1   - extra logs

case ${EAPI:-0} in
  8|9) ;;
  *) die "huggingface-r1.eclass requires EAPI >= 8" ;;
esac

# Mark as VCS-like by default; consumers may override in ebuild if desired.
PROPERTIES+=" live"

inherit python-any-r1

# ----------------------------
# Public eclass variables
# ----------------------------

: "${HUGGINGFACE_CACHE_DIR:=}"   # Optional override for cache (default set in functions)
: "${HUGGINGFACE_OFFLINE:=}"     # "1" to force offline
: "${HUGGINGFACE_TOKEN:=}"       # HF token; falls back to HF_TOKEN if unset
: "${HUGGINGFACE_VERBOSE:=}"     # "1" for extra logging

# # Convenience dependency you can include in your ebuild
# HUGGINGFACE_BDEPEND="
#   $(python_gen_any_dep 'sci-ml/huggingface_hub[${PYTHON_USEDEP}]')
# "

# --- Convenience dependency (configurable) -------------------

# Default to the common name, but allow overlays to override.
: "${HUGGINGFACE_ATOM:=sci-ml/huggingface_hub}"

# If 1, require matching python_targets via ${PYTHON_USEDEP} (python-any-r1).
# If 0, do NOT require python_targets (useful for overlays without python-r1 on this pkg).
: "${HUGGINGFACE_REQUIRE_PYTHON_USEDEP:=1}"

# Extra USE requirements to append inside the [] dep, comma-separated.
# Example (in ebuild): HUGGINGFACE_EXTRA_USE="xet"
: "${HUGGINGFACE_EXTRA_USE:=xet}"

# Build the final HUGGINGFACE_BDEPEND
_hf_build_bdepend() {
  local usechunk=""
  if [[ ${HUGGINGFACE_REQUIRE_PYTHON_USEDEP} == 1 ]]; then
    usechunk="${PYTHON_USEDEP}"
  fi
  if [[ -n ${HUGGINGFACE_EXTRA_USE} ]]; then
    [[ -n ${usechunk} ]] && usechunk+=","
    usechunk+="${HUGGINGFACE_EXTRA_USE}"
  fi

  if [[ ${HUGGINGFACE_REQUIRE_PYTHON_USEDEP} == 1 ]]; then
    if [[ -n ${usechunk} ]]; then
      # python_any_dep expands to an OR over all enabled targets with the same [].
      HUGGINGFACE_BDEPEND="$(python_gen_any_dep \"${HUGGINGFACE_ATOM}[${usechunk}]\")"
    else
      HUGGINGFACE_BDEPEND="$(python_gen_any_dep \"${HUGGINGFACE_ATOM}\")"
    fi
  else
    # No python_targets constraint; append only extra USE (if any).
    if [[ -n ${usechunk} ]]; then
      HUGGINGFACE_BDEPEND="${HUGGINGFACE_ATOM}[${usechunk}]"
    else
      HUGGINGFACE_BDEPEND="${HUGGINGFACE_ATOM}"
    fi
  fi
}
_hf_build_bdepend
unset -f _hf_build_bdepend


# ----------------------------
# Internal helpers
# ----------------------------

_hf_python_setup() {
  python-any-r1_pkg_setup
  export EPYTHON PYTHONPATH
}

_hf_log() {
  if [[ ${HUGGINGFACE_VERBOSE} == 1 ]]; then
    einfo "[huggingface-r1] $*"
  fi
}

# Parse SRC_URI into JSON list of {uri, dest}
_hf_extract_hf_pairs() {
  local -a words=()
  # shellcheck disable=SC2206
  words=( ${SRC_URI} )
  local i=0
  local n=${#words[@]}
  local uri dest
  local json="["

  while (( i < n )); do
    uri=${words[i]}
    dest=""
    if (( i + 2 < n )) && [[ ${words[i+1]} == "->" ]]; then
      dest=${words[i+2]}
      i=$(( i + 3 ))
    else
      i=$(( i + 1 ))
    fi
    if [[ ${uri} == hf+* ]]; then
      [[ ${json} != "[" ]] && json+=","
      json+="{\"uri\":\"${uri//\"/\\\"}\",\"dest\":"
      if [[ -n ${dest} ]]; then
        json+="\"${dest//\"/\\\"}\"}"
      else
        json+="null}"
      fi
    fi
  done
  json+="]"
  echo "${json}"
}

# Do we have any hf+ entries in SRC_URI?
_hf_has_hf_src_uri() {
  local pairs_json
  pairs_json=$(_hf_extract_hf_pairs)
  _hf_log "_hf_has_hf_src_uri: SRC_URI='${SRC_URI}'"
  _hf_log "_hf_has_hf_src_uri: pairs_json=${pairs_json}"
  [[ ${pairs_json} != "[]" ]]
}

# Build a single-entry "pairs" JSON from HF_* variables (git-r3 style).
# Uses directory output by default (no tar), unless HF_DEST ends with .tar(.gz|.xz).
_hf_pairs_from_vars() {
  local type repo rev dest query uri json
  type=${HF_REPO_TYPE:-model}
  repo=${HF_REPO_ID}
  rev=${HF_REV:-main}
  dest=${HF_DEST}

  [[ -z ${repo} ]] && echo "[]" && return 0

  # HF_IGNORE: accept space- or comma-separated patterns
  local IFS_backup=${IFS}
  local -a pats=()
  if [[ -n ${HF_IGNORE} ]]; then
    IFS=', ' read -r -a pats <<< "${HF_IGNORE}"
  fi
  IFS=${IFS_backup}

  if (( ${#pats[@]} )); then
    local joined
    printf -v joined "%s," "${pats[@]}"
    joined=${joined%,}
    query="?ignore=${joined}"
  else
    query=""
  fi

  uri="hf+repo:${type}:${repo}@${rev}${query}"

  json="["
  json+="{\"uri\":\"${uri//\"/\\\"}\",\"dest\":"
  if [[ -n ${dest} ]]; then
    json+="\"${dest//\"/\\\"}\"}"
  else
    json+="null}"
  fi
  json+="]"
  echo "${json}"
}

# Run embedded Python helper.
# IMPORTANT: The payload is passed via HF_ECLASS_PAYLOAD (env var), not stdin.
_hf_python_eval() {
  "${EPYTHON}" - <<'PYCODE'
import os, sys, json, tarfile, pathlib, shutil
from typing import Optional

try:
  from huggingface_hub import hf_hub_download, snapshot_download
except Exception as e:
  print(f"[huggingface-r1] ERROR: missing huggingface_hub: {e}", file=sys.stderr)
  sys.exit(2)

def _ensure_dir(p: pathlib.Path): p.mkdir(parents=True, exist_ok=True)

def _tar_repro(src_dir: pathlib.Path, dst_tar: pathlib.Path):
  if str(dst_tar).endswith(".tar.gz"):
    mode="w:gz"
  elif str(dst_tar).endswith(".tar.xz"):
    mode="w:xz"
  elif str(dst_tar).endswith(".tar"):
    mode="w"
  else:
    raise RuntimeError(f"Unknown tar extension for {dst_tar}")

  entries = []
  for root, dirs, files in os.walk(src_dir):
    root_p = pathlib.Path(root)
    dirs.sort()
    files.sort()
    for d in dirs: entries.append((root_p / d, True))
    for f in files: entries.append((root_p / f, False))

  with tarfile.open(dst_tar, mode) as tf:
    def _norm(info: tarfile.TarInfo) -> tarfile.TarInfo:
      info.uid = 0; info.gid = 0
      info.uname = ""; info.gname = ""
      info.mtime = 0
      return info

    top = tarfile.TarInfo(name=src_dir.name + "/")
    top.type = tarfile.DIRTYPE
    top = _norm(top)
    tf.addfile(top)

    for path, is_dir in entries:
      arcname = src_dir.name + "/" + str(path.relative_to(src_dir)).replace("\\","/")
      info = tf.gettarinfo(str(path), arcname=arcname)
      info = _norm(info)
      if info.isfile():
        with open(path, "rb") as f:
          tf.addfile(info, f)
      else:
        tf.addfile(info)

def parse_hf_uri(raw: str):
  if not raw.startswith("hf+"): return None
  scheme, rest = raw.split(":", 1)
  kind = scheme.replace("hf+", "")       # file | repo
  if ":" not in rest: raise ValueError(f"Invalid HF URI (missing type): {raw}")
  hftype, rest2 = rest.split(":", 1)     # model | dataset | space
  qpos = rest2.find("?")
  base = rest2 if qpos < 0 else rest2[:qpos]
  query = "" if qpos < 0 else rest2[qpos+1:]
  if "@" in base: repo_id, revision = base.split("@", 1)
  else:           repo_id, revision = base, None
  q = {}
  if query:
    for kv in query.split("&"):
      if not kv: continue
      if "=" in kv: k, v = kv.split("=", 1)
      else:         k, v = kv, ""
      q[k] = v
  return {"kind": kind, "type": hftype, "repo_id": repo_id, "revision": revision, "query": q}

def dl_file(entry, work_dir: pathlib.Path, dest_name: Optional[str], token: Optional[str],
            cache_dir: Optional[pathlib.Path], offline: bool) -> pathlib.Path:
  path = entry["query"].get("path")
  if not path: raise ValueError("hf+file requires ?path=<path/in/repo>")
  repo_type, repo_id, revision = entry["type"], entry["repo_id"], entry["revision"]
  _ensure_dir(work_dir)
  if cache_dir: os.environ.setdefault("HF_HOME", str(cache_dir))
  if offline:   os.environ["HF_HUB_OFFLINE"] = "1"
  tmp = work_dir / ".hf_tmp_file"
  _ensure_dir(tmp)
  p = hf_hub_download(repo_id=repo_id, filename=path, repo_type=repo_type,
                      revision=revision, token=token,
                      local_dir=str(tmp), local_dir_use_symlinks=False)
  out = work_dir / (dest_name or pathlib.Path(p).name)
  if out.exists():
    if out.is_dir(): shutil.rmtree(out, ignore_errors=True)
    else: out.unlink()
  shutil.move(p, out)
  shutil.rmtree(tmp, ignore_errors=True)
  return out

def dl_repo(entry, materialize_dir: pathlib.Path, token: Optional[str],
           cache_dir: Optional[pathlib.Path], offline: bool) -> pathlib.Path:
  repo_type, repo_id, revision = entry["type"], entry["repo_id"], entry["revision"]
  ig = entry["query"].get("ignore", "")
  ignores = [x.strip() for x in ig.split(",") if x.strip()] if ig else None
  if cache_dir: os.environ.setdefault("HF_HOME", str(cache_dir))
  if offline:   os.environ["HF_HUB_OFFLINE"] = "1"
  _ensure_dir(materialize_dir)
  snapshot_download(repo_id=repo_id, repo_type=repo_type, revision=revision,
                    token=token, local_dir=str(materialize_dir),
                    local_dir_use_symlinks=False,
                    ignore_patterns=ignores)
  return materialize_dir

def main():
  raw = os.environ.get("HF_ECLASS_PAYLOAD", "")
  if not raw: raw = sys.stdin.read()
  spec = json.loads(raw)

  mode     = spec.get("mode", "fetch")   # "fetch" or "unpack"
  out_root = pathlib.Path(spec["out_root"])
  token    = spec.get("token") or os.environ.get("HF_TOKEN") or None
  cache_dir= pathlib.Path(spec["cache_dir"]) if spec.get("cache_dir") else None
  offline  = bool(spec.get("offline"))
  entries  = spec["entries"]
  _ensure_dir(out_root)

  results=[]

  if mode == "fetch":
    distdir = pathlib.Path(spec["distdir"])
    _ensure_dir(distdir)
    for e in entries:
      meta = parse_hf_uri(e["uri"])
      if not meta: continue
      dest = e.get("dest")
      if meta["kind"] == "file":
        staged = dl_file(meta, out_root, dest, token, cache_dir, offline)
        final = distdir / (dest or staged.name)
        if final.exists():
          if final.is_dir(): shutil.rmtree(final, ignore_errors=True)
          else: final.unlink()
        shutil.move(staged, final)
        results.append({"uri": e["uri"], "path": str(final), "type": "file"})
      elif meta["kind"] == "repo":
        # Must be a tarball; synthesize if missing
        if not dest or not (dest.endswith(".tar") or dest.endswith(".tar.gz") or dest.endswith(".tar.xz")):
          base = meta["repo_id"].replace("/", "__")
          if meta["revision"]: base += f"-{meta['revision'][:12]}"
          dest = f"{base}.tar.gz"
        stage_dir = out_root / (meta["repo_id"].replace("/", "__") + (f"-{meta['revision'][:12]}" if meta["revision"] else ""))
        dl_repo(meta, stage_dir, token, cache_dir, offline)
        tar_path = distdir / dest
        if tar_path.exists(): tar_path.unlink()
        _tar_repro(stage_dir, tar_path)
        results.append({"uri": e["uri"], "path": str(tar_path), "type": "tar"})
      else:
        raise RuntimeError(f"Unknown kind {meta['kind']}")
    print(json.dumps(results))
    return

  if mode == "unpack":
    for e in entries:
      meta = parse_hf_uri(e["uri"])
      if not meta: continue
      dest = e.get("dest")
      if meta["kind"] == "file":
        p = dl_file(meta, out_root, dest, token, cache_dir, offline)
        results.append({"uri": e["uri"], "path": str(p), "type": "file"})
      elif meta["kind"] == "repo":
        stage_dir = out_root / (meta["repo_id"].replace("/", "__") + (f"-{meta['revision'][:12]}" if meta["revision"] else ""))
        dl_repo(meta, stage_dir, token, cache_dir, offline)
        if dest and (dest.endswith(".tar") or dest.endswith(".tar.gz") or dest.endswith(".tar.xz")):
          tar_path = out_root / dest
          if tar_path.exists(): tar_path.unlink()
          _tar_repro(stage_dir, tar_path)
          results.append({"uri": e["uri"], "path": str(tar_path), "type": "tar"})
        else:
          results.append({"uri": e["uri"], "path": str(stage_dir), "type": "dir"})
      else:
        raise RuntimeError(f"Unknown kind {meta['kind']}")
    print(json.dumps(results))
    return

  raise RuntimeError(f"Unknown mode {mode!r}")

if __name__ == "__main__":
  main()
PYCODE
}

# ----------------------------
# Phase implementations (exported)
# ----------------------------

# Optional fetch-phase support for hf+ entries in SRC_URI (not used in git-r3 style)
huggingface-r1_src_fetch() {
  _hf_python_setup

  local pairs_json=$(_hf_extract_hf_pairs)
  if [[ ${pairs_json} == "[]" ]]; then
    _hf_log "huggingface-r1_src_fetch: no hf+* entries in SRC_URI; nothing to do"
    return 0
  fi

  local stage="${T}/huggingface-stage"
  mkdir -p "${stage}" || die
  local cache_dir="${HUGGINGFACE_CACHE_DIR:-${T}/huggingface-cache}"
  mkdir -p "${cache_dir}" || die

  einfo "[huggingface-r1] fetch: writing artifacts to DISTDIR=${DISTDIR}"

  local payload result status
  payload=$(cat <<-JSON
{
  "mode": "fetch",
  "out_root": "${stage}",
  "distdir": "${DISTDIR}",
  "token": "${HUGGINGFACE_TOKEN}",
  "cache_dir": "${cache_dir}",
  "offline": ${HUGGINGFACE_OFFLINE:-false},
  "entries": ${pairs_json}
}
JSON
)
  result=$(HF_ECLASS_PAYLOAD="${payload}" _hf_python_eval); status=$?
  if [[ ${status} -ne 0 ]]; then
    die "huggingface-r1_src_fetch: helper failed (status ${status})"
  fi

  einfo "[huggingface-r1] fetch results: ${result}"
}

# The ONE src_unpack Portage will call (via EXPORT_FUNCTIONS)
huggingface-r1_src_unpack() {
  ewarn "[huggingface-r1] src_unpack start"
  ewarn "[huggingface-r1] HF_REPO_ID='${HF_REPO_ID}'  SRC_URI='${SRC_URI}'"

  local did_hf=0

  if [[ -n ${HF_REPO_ID} ]]; then
    # --- git-r3 style via HF_* variables ---
    _hf_python_setup

    local out_root="${WORKDIR}/huggingface"
    mkdir -p "${out_root}" || die
    local cache_dir="${HUGGINGFACE_CACHE_DIR:-${T}/huggingface-cache}"
    mkdir -p "${cache_dir}" || die

    local pairs_json payload result status
    pairs_json=$(_hf_pairs_from_vars)
    ewarn "[huggingface-r1] vars => ${pairs_json}"

    payload=$(cat <<-JSON
{
  "mode": "unpack",
  "out_root": "${out_root}",
  "token": "${HUGGINGFACE_TOKEN}",
  "cache_dir": "${cache_dir}",
  "offline": ${HUGGINGFACE_OFFLINE:-false},
  "entries": ${pairs_json}
}
JSON
)
    result=$(HF_ECLASS_PAYLOAD="${payload}" _hf_python_eval); status=$?
    if [[ ${status} -ne 0 ]]; then
      die "huggingface-r1_src_unpack: helper failed (status ${status})"
    fi
    ewarn "[huggingface-r1] vars result: ${result}"
    did_hf=1

  elif _hf_has_hf_src_uri; then
    # --- compatibility: hf+ entries in SRC_URI ---
    _hf_python_setup

    local out_root="${WORKDIR}/huggingface"
    mkdir -p "${out_root}" || die
    local cache_dir="${HUGGINGFACE_CACHE_DIR:-${T}/huggingface-cache}"
    mkdir -p "${cache_dir}" || die

    local pairs_json payload result status
    pairs_json=$(_hf_extract_hf_pairs)
    ewarn "[huggingface-r1] SRC_URI => ${pairs_json}"

    payload=$(cat <<-JSON
{
  "mode": "unpack",
  "out_root": "${out_root}",
  "token": "${HUGGINGFACE_TOKEN}",
  "cache_dir": "${cache_dir}",
  "offline": ${HUGGINGFACE_OFFLINE:-false},
  "entries": ${pairs_json}
}
JSON
)
    result=$(HF_ECLASS_PAYLOAD="${payload}" _hf_python_eval); status=$?
    if [[ ${status} -ne 0 ]]; then
      die "huggingface-r1_src_unpack: helper failed (status ${status})"
    fi

    ewarn "[huggingface-r1] SRC_URI result: ${result}"
    did_hf=1
  else
    ewarn "[huggingface-r1] nothing to fetch (no HF_* and no hf+ URIs)"
  fi

  # Always unpack any regular distfiles too
  default

  if [[ ${did_hf} -eq 0 ]]; then
    ewarn "[huggingface-r1] src_unpack performed no HF work"
  fi
}

# Export the phase functions so ebuilds don't need to define them.
EXPORT_FUNCTIONS src_fetch src_unpack
