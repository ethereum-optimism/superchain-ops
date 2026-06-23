#!/bin/sh
set -eu

# Sourced from https://mise.run/.
# A local, static copy is maintained to reduce the risk of introducing a vulnerable `mise` version.
# To update, replace the contents of this file with the latest script from https://mise.run/ to ensure you're using the most recent version.
# Use caution when updating, as changes may affect setup or security.

#region logging setup
if [ "${MISE_DEBUG-}" = "true" ] || [ "${MISE_DEBUG-}" = "1" ]; then
  debug() {
    echo "$@" >&2
  }
else
  debug() {
    :
  }
fi

if [ "${MISE_QUIET-}" = "1" ] || [ "${MISE_QUIET-}" = "true" ]; then
  info() {
    :
  }
else
  info() {
    echo "$@" >&2
  }
fi

error() {
  echo "$@" >&2
  exit 1
}
#endregion

#region environment setup
get_os() {
  os="$(uname -s)"
  if [ "$os" = Darwin ]; then
    echo "macos"
  elif [ "$os" = Linux ]; then
    echo "linux"
  else
    error "unsupported OS: $os"
  fi
}

get_arch() {
  musl=""
  if type ldd >/dev/null 2>/dev/null; then
    libc=$(ldd /bin/ls | grep 'musl' | head -1 | cut -d ' ' -f1)
    if [ -n "$libc" ]; then
      musl="-musl"
    fi
  fi
  arch="$(uname -m)"
  if [ "$arch" = x86_64 ]; then
    echo "x64$musl"
  elif [ "$arch" = aarch64 ] || [ "$arch" = arm64 ]; then
    echo "arm64$musl"
  elif [ "$arch" = armv7l ]; then
    echo "armv7$musl"
  else
    error "unsupported architecture: $arch"
  fi
}

get_ext() {
  if [ -n "${MISE_INSTALL_EXT:-}" ]; then
    echo "$MISE_INSTALL_EXT"
  elif [ -n "${MISE_VERSION:-}" ] && echo "$MISE_VERSION" | grep -q '^v2024'; then
    # 2024 versions don't have zstd tarballs
    echo "tar.gz"
  elif tar_supports_zstd; then
    echo "tar.zst"
  elif command -v zstd >/dev/null 2>&1; then
    echo "tar.zst"
  else
    echo "tar.gz"
  fi
}

tar_supports_zstd() {
  # tar is bsdtar or version is >= 1.31
  if tar --version | grep -q 'bsdtar' && command -v zstd >/dev/null 2>&1; then
    true
  elif tar --version | grep -q '1\.(3[1-9]|[4-9][0-9]'; then
    true
  else
    false
  fi
}

shasum_bin() {
  if command -v shasum >/dev/null 2>&1; then
    echo "shasum"
  elif command -v sha256sum >/dev/null 2>&1; then
    echo "sha256sum"
  else
    error "mise install requires shasum or sha256sum but neither is installed. Aborting."
  fi
}

get_checksum() {
  version=$1
  os="$(get_os)"
  arch="$(get_arch)"
  ext="$(get_ext)"
  url="https://github.com/jdx/mise/releases/download/v${version}/SHASUMS256.txt"

  # For current version use static checksum otherwise
  # use checksum from releases
  if [ "$version" = "2026.5.18" ]; then
    checksum_linux_x86_64="9359889a0cb729fbbfca7fc65d76bf5e05bdf9ad1873ae2f56e431a068187c12  ./mise-v2026.5.18-linux-x64.tar.gz"
    checksum_linux_x86_64_musl="3078e9f0dc9a65cdd873abea9713cbdbeef97fcf8c28dac70b57bf64f1d7f219  ./mise-v2026.5.18-linux-x64-musl.tar.gz"
    checksum_linux_arm64="4c3604cdf9e8b7b5f2a16456454009a6fceb5b1c592d0075201edd2512ecafdc  ./mise-v2026.5.18-linux-arm64.tar.gz"
    checksum_linux_arm64_musl="fdabce5f26ffbaa9ce6d0ff6e34a5ed719b7b7936c4da996a1ccdbeead04a3c1  ./mise-v2026.5.18-linux-arm64-musl.tar.gz"
    checksum_linux_armv7="2480a266e2d4b44f7c5c4346e521f206c93add97ef887a1fc081d756b0d90799  ./mise-v2026.5.18-linux-armv7.tar.gz"
    checksum_linux_armv7_musl="ff3bbf3261c6b59fc04c3b6799c1917c406a27097e7647666ba5bd534451a020  ./mise-v2026.5.18-linux-armv7-musl.tar.gz"
    checksum_macos_x86_64="1e202d6a4dbba53b395cebe8227f74c31d3e7641328189f1ec141cd4460215d9  ./mise-v2026.5.18-macos-x64.tar.gz"
    checksum_macos_arm64="5a33a37924af58b0e6e983b69447b90a4e1f33f4ee503600a943d99f6c08b2df  ./mise-v2026.5.18-macos-arm64.tar.gz"
    checksum_linux_x86_64_zstd="ad7ab8bdf98e4532434c02b6401da29d595546300539180aa02c1f4c19977ac3  ./mise-v2026.5.18-linux-x64.tar.zst"
    checksum_linux_x86_64_musl_zstd="6ecbcf8a83e7a87af6ec9b4b253366334807a8d475e2d9445d718f7a36185e2f  ./mise-v2026.5.18-linux-x64-musl.tar.zst"
    checksum_linux_arm64_zstd="b885d6bd3b383fa497ed6987da26f65d86b5796cd904de83a240a273b9b1a340  ./mise-v2026.5.18-linux-arm64.tar.zst"
    checksum_linux_arm64_musl_zstd="af3c216779e8fbc7fe68a05ad693a35bb903cd71768f2b8b7768da44080661c5  ./mise-v2026.5.18-linux-arm64-musl.tar.zst"
    checksum_linux_armv7_zstd="c98992d051f4f06b4e7c43c4a70680252d5ce9e3a4daf1322cf512c9ec0c828d  ./mise-v2026.5.18-linux-armv7.tar.zst"
    checksum_linux_armv7_musl_zstd="2960a5b6e496174dd2592791732e92536d57e2498d287f9626f49a6ff04bf5a6  ./mise-v2026.5.18-linux-armv7-musl.tar.zst"
    checksum_macos_x86_64_zstd="7862421f36d679f2b2e6e5fbdeb4f0ee5fa7a899cd8fd5b7da86639a421d85bd  ./mise-v2026.5.18-macos-x64.tar.zst"
    checksum_macos_arm64_zstd="06db63fbd40a8ca5abea9bc7a772a8cc5a1b008b89e9be1cfe81d22cec433097  ./mise-v2026.5.18-macos-arm64.tar.zst"

    # TODO: refactor this, it's a bit messy
    if [ "$(get_ext)" = "tar.zst" ]; then
      if [ "$os" = "linux" ]; then
        if [ "$arch" = "x64" ]; then
          echo "$checksum_linux_x86_64_zstd"
        elif [ "$arch" = "x64-musl" ]; then
          echo "$checksum_linux_x86_64_musl_zstd"
        elif [ "$arch" = "arm64" ]; then
          echo "$checksum_linux_arm64_zstd"
        elif [ "$arch" = "arm64-musl" ]; then
          echo "$checksum_linux_arm64_musl_zstd"
        elif [ "$arch" = "armv7" ]; then
          echo "$checksum_linux_armv7_zstd"
        elif [ "$arch" = "armv7-musl" ]; then
          echo "$checksum_linux_armv7_musl_zstd"
        else
          warn "no checksum for $os-$arch"
        fi
      elif [ "$os" = "macos" ]; then
        if [ "$arch" = "x64" ]; then
          echo "$checksum_macos_x86_64_zstd"
        elif [ "$arch" = "arm64" ]; then
          echo "$checksum_macos_arm64_zstd"
        else
          warn "no checksum for $os-$arch"
        fi
      else
        warn "no checksum for $os-$arch"
      fi
    else
      if [ "$os" = "linux" ]; then
        if [ "$arch" = "x64" ]; then
          echo "$checksum_linux_x86_64"
        elif [ "$arch" = "x64-musl" ]; then
          echo "$checksum_linux_x86_64_musl"
        elif [ "$arch" = "arm64" ]; then
          echo "$checksum_linux_arm64"
        elif [ "$arch" = "arm64-musl" ]; then
          echo "$checksum_linux_arm64_musl"
        elif [ "$arch" = "armv7" ]; then
          echo "$checksum_linux_armv7"
        elif [ "$arch" = "armv7-musl" ]; then
          echo "$checksum_linux_armv7_musl"
        else
          warn "no checksum for $os-$arch"
        fi
      elif [ "$os" = "macos" ]; then
        if [ "$arch" = "x64" ]; then
          echo "$checksum_macos_x86_64"
        elif [ "$arch" = "arm64" ]; then
          echo "$checksum_macos_arm64"
        else
          warn "no checksum for $os-$arch"
        fi
      else
        warn "no checksum for $os-$arch"
      fi
    fi
  else
    if command -v curl >/dev/null 2>&1; then
      debug ">" curl -fsSL "$url"
      checksums="$(curl --compressed -fsSL "$url")"
    else
      if command -v wget >/dev/null 2>&1; then
        debug ">" wget -qO - "$url"
        stderr=$(mktemp)
        checksums="$(wget -qO - "$url")"
      else
        error "mise standalone install specific version requires curl or wget but neither is installed. Aborting."
      fi
    fi
    # TODO: verify with minisign or gpg if available

    checksum="$(echo "$checksums" | grep "$os-$arch.$ext")"
    if ! echo "$checksum" | grep -Eq "^([0-9a-f]{32}|[0-9a-f]{64})"; then
      warn "no checksum for mise $version and $os-$arch"
    else
      echo "$checksum"
    fi
  fi
}

#endregion

download_file() {
  url="$1"
  filename="$(basename "$url")"
  cache_dir="$(mktemp -d)"
  file="$cache_dir/$filename"

  info "mise: installing mise..."

  if command -v curl >/dev/null 2>&1; then
    debug ">" curl -#fLo "$file" "$url"
    curl -#fLo "$file" "$url"
  else
    if command -v wget >/dev/null 2>&1; then
      debug ">" wget -qO "$file" "$url"
      stderr=$(mktemp)
      wget -O "$file" "$url" >"$stderr" 2>&1 || error "wget failed: $(cat "$stderr")"
    else
      error "mise standalone install requires curl or wget but neither is installed. Aborting."
    fi
  fi

  echo "$file"
}

install_mise() {
  version="${MISE_VERSION:-v2026.5.18}"
  version="${version#v}"
  os="$(get_os)"
  arch="$(get_arch)"
  ext="$(get_ext)"
  install_path="${MISE_INSTALL_PATH:-$HOME/.local/bin/mise}"
  install_dir="$(dirname "$install_path")"
  tarball_url="https://github.com/jdx/mise/releases/download/v${version}/mise-v${version}-${os}-${arch}.${ext}"

  cache_file=$(download_file "$tarball_url")
  debug "mise-setup: tarball=$cache_file"

  debug "validating checksum"
  cd "$(dirname "$cache_file")" && get_checksum "$version" | "$(shasum_bin)" -c >/dev/null

  # extract tarball
  mkdir -p "$install_dir"
  rm -rf "$install_path"
  cd "$(mktemp -d)"
  if [ "$(get_ext)" = "tar.zst" ] && ! tar_supports_zstd; then
    zstd -d -c "$cache_file" | tar -xf -
  else
    tar -xf "$cache_file"
  fi
  mv mise/bin/mise "$install_path"
  info "mise: installed successfully to $install_path"
}

cleanup_stale_foundry_mise_backends() {
  data_dir="${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}"

  for tool in forge cast anvil; do
    backend_file="$data_dir/installs/$tool/.mise.backend.toml"

    if [ -f "$backend_file" ] && grep -q 'full = "ubi:foundry-rs/foundry"' "$backend_file"; then
      info "mise: removing stale $tool install from the old Foundry UBI alias"
      rm -rf "$data_dir/installs/$tool"
    fi
  done
}

after_finish_help() {
  case "${SHELL:-}" in
  */zsh)
    info "mise: run the following to activate mise in your shell:"
    info "echo \"eval \\\"\\\$($install_path activate zsh)\\\"\" >> \"${ZDOTDIR-$HOME}/.zshrc\""
    info ""
    info "mise: run \`mise doctor\` to verify this is setup correctly"
    ;;
  */bash)
    info "mise: run the following to activate mise in your shell:"
    info "echo \"eval \\\"\\\$($install_path activate bash)\\\"\" >> ~/.bashrc"
    info ""
    info "mise: run \`mise doctor\` to verify this is setup correctly"
    ;;
  */fish)
    info "mise: run the following to activate mise in your shell:"
    info "echo \"$install_path activate fish | source\" >> ~/.config/fish/config.fish"
    info ""
    info "mise: run \`mise doctor\` to verify this is setup correctly"
    ;;
  *)
    info "mise: run \`$install_path --help\` to get started"
    ;;
  esac
}

install_mise
cleanup_stale_foundry_mise_backends
if [ "${MISE_INSTALL_HELP-}" != 0 ]; then
  after_finish_help
fi
