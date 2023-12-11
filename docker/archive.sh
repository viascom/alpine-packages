#!/usr/bin/env bash
# Ensures that packages and their dependencies are fetched for all architectures, indexed, and the index is signed.

# Constants
readonly REPO_PATH="$HOME/packages"
readonly ARCHS=("aarch64" "armhf" "armv7" "ppc64le" "s390x" "x86" "x86_64")
readonly LOG_FILE="/var/log/alpine-packages/packages.log"

error() {
  local msg="$*"
  echo "[$(date +'%Y-%m-%dT%H:%M:%S')] ERROR: $msg" >&2
  exit 1
}

warning() {
  local msg="$*"
  echo "[$(date +'%Y-%m-%dT%H:%M:%S')] WARNING: $msg" >&1
}

info() {
  local msg="$*"
  echo "[$(date +'%Y-%m-%dT%H:%M:%S')] INFO: $msg" >&1
}

check_dependencies() {
  local dependencies=("apk" "abuild-sign")
  local cmd
  for cmd in "${dependencies[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      error "Command $cmd is not available. Please install it before running this script."
    fi
  done
}

fetch_packages() {
  local package_name=$1
  local arch
  local arch_path
  local fetched_archs=()

  for arch in "${ARCHS[@]}"; do
    arch_path="${REPO_PATH}/${arch}"
    mkdir -p "${arch_path}" || continue
    pushd "${arch_path}" >/dev/null || continue
    if apk fetch --verbose --no-interactive --no-cache --allow-untrusted --arch "${arch}" --recursive "${package_name}"; then
      info "Fetched '${package_name}' for architecture '${arch}'."
      fetched_archs+=("$arch")
    else
      warning "Failed to fetch '${package_name}' for architecture '${arch}'. Continuing..."
    fi
    popd >/dev/null || exit
  done

  log_package "$package_name" "${fetched_archs[@]}"
}

log_package() {
  local package_name=$1
  shift
  local archs=("$@")
  local date_added
  local date_added=$(date +'%Y-%m-%dT%H:%M:%S')
  local alpine_version=$(cat /etc/alpine-release)

  local old_ifs="$IFS"
  IFS=', '

  mkdir -p "$(dirname "$LOG_FILE")"
  printf "%s | %s | %s | %s\n" "$package_name" "$date_added" "${archs[*]}" "$alpine_version" >>"$LOG_FILE"

  IFS="$old_ifs"
}

index_and_sign() {
  local arch
  local arch_path

  for arch in "${ARCHS[@]}"; do
    arch_path="${REPO_PATH}/${arch}"
    if [ -d "${arch_path}" ] && [ "$(ls -A "${arch_path}")" ]; then
      # Change to the architecture-specific directory
      pushd "${arch_path}" >/dev/null || exit
      pwd

      # Perform the indexing within the architecture-specific directory
      # Using the absolute path for the index file to ensure correctness
      if ! apk index --merge --verbose --update-cache --allow-untrusted --no-interactive -x APKINDEX.tar.gz -o APKINDEX.tar.gz ./*.apk; then
        warning "Failed to create the package index for architecture '${arch}'."
      fi

      # Sign the index file. The index file is now in the current directory, so no path is needed
      if ! abuild-sign -k ~/.abuild/viascom.rsa APKINDEX.tar.gz; then
        warning "Failed to sign the package index for architecture '${arch}'."
      fi

      info "Indexed and signed the package index for architecture '${arch}'."

      # Return to the original directory
      popd >/dev/null || exit
    else
      warning "No packages found for architecture '${arch}', skipping indexing and signing."
    fi
  done

}

main() {
  check_dependencies

  # Check if at least one package name was provided
  if [ "$#" -lt 1 ]; then
    error "Usage: $0 <package-name> [<package-name> ...]"
  fi

  # Fetch packages for each architecture
  local package_name
  for package_name in "$@"; do
    fetch_packages "${package_name}"
  done

  # Index and sign packages for each architecture
  index_and_sign

  info "All operations completed."
}

# Call the main function passing all the arguments to it
main "$@"
