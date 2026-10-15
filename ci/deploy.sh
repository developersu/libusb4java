#!/usr/bin/env bash
# Sign the prebuilt per-platform native JARs (from target/) with GPG and
# install them into the local Maven repository (always). Deployment to the
# remote release repository defined in pom.xml distributionManagement
# (id=redrise) is performed only after explicit user confirmation.
#
#   Usage:
#     bash ci/deploy.sh                 # uses VERSION from pom.xml, jars in target/
#     VERSION=1.0.30 DIR=target bash ci/deploy.sh
#
# Requires: mvn, gpg (a GPG signing key already selected, e.g. via
# gpg-preset-passphrase or a cached agent). Remote credentials are taken from
# the REPO_USERNAME / REPO_PASSWORD environment variables (only needed for
# the remote deploy step; ~/.m2/settings.xml is NOT consulted).

set -euo pipefail

VERSION="${VERSION:-$(grep -m1 -oP '(?<=<version>).+(?=</version>)' pom.xml)}"
DIR="${DIR:-target}"
POM="pom.xml"

# GAV coordinates (explicit, so deploy-file does NOT need -DpomFile: with
# pomFile the plugin resolves the POM artifact from the remote repository,
# which fails on the very first deploy of a version).
GROUP_ID="$(grep -m1 -oP '(?<=<groupId>).+(?=</groupId>)' "$POM")"
ARTIFACT_ID="$(grep -m1 -oP '(?<=<artifactId>).+(?=</artifactId>)' "$POM")"
if [ -z "$GROUP_ID" ] || [ -z "$ARTIFACT_ID" ]; then
  echo "could not resolve groupId/artifactId in $POM" >&2
  exit 1
fi

# Derive CLASSIFIERS dynamically from the per-platform JARs present in DIR
# (expected naming: libusb4java-$VERSION-<classifier>.jar).
CLASSIFIERS=()
for j in "$DIR"/libusb4java-"$VERSION"-*.jar; do
  [ -e "$j" ] || continue
  c="$(basename "$j")"
  c="${c#libusb4java-$VERSION-}"
  c="${c%.jar}"
  CLASSIFIERS+=("$c")
done
if [ ${#CLASSIFIERS[@]} -eq 0 ]; then
  echo "no libusb4java-$VERSION-*.jar found in $DIR" >&2
  exit 1
fi

# Repository coordinates from pom.xml distributionManagement.
DM_BLOCK="$(awk '/<distributionManagement>/,/<\/distributionManagement>/' "$POM")"
REPO_ID="$(printf '%s\n' "$DM_BLOCK" | grep -m1 -oP '(?<=<id>).*?(?=</id>)')"
REPO_URL="$(printf '%s\n' "$DM_BLOCK" | grep -m1 -oP '(?<=<url>).*?(?=</url>)')"
if [ -z "$REPO_ID" ] || [ -z "$REPO_URL" ]; then
  echo "could not resolve distributionManagement repository in $POM" >&2
  exit 1
fi

sign() {
  gpg --batch --yes --armor --detach-sign --output "$1.asc" "$1"
}

# 1) Sign + install the POM into the local repository
sign "$POM"
mvn -q install:install-file \
  -Dfile="$POM" \
  -DpomFile="$POM" \
  -Dpackaging=pom

# 2) Sign + install each platform JAR into the local repository
for c in "${CLASSIFIERS[@]}"; do
  f="$DIR/libusb4java-$VERSION-$c.jar"
  if [ ! -f "$f" ]; then
    echo "missing artifact: $f" >&2
    exit 1
  fi
  sign "$f"
  mvn -q install:install-file \
    -Dfile="$f" \
    -DpomFile="$POM" \
    -Dpackaging=jar \
    -Dclassifier="$c"
  echo "installed: libusb4java-$VERSION-$c"
done

echo "Done: installed libusb4java $VERSION (pom + ${#CLASSIFIERS[@]} classifiers) into local m2"

# 3) Remote deploy only with explicit user consent
answer=""
read -r -p "Deploy to remote repository ${REPO_URL} (id=${REPO_ID})? [y/N] " answer || true
case "${answer,,}" in
  y|yes) ;;
  *)
    echo "Remote deploy skipped"
    exit 0
    ;;
esac

# 4) Remote credentials from environment variables (never from settings.xml)
if [ -z "${REPO_USERNAME:-}" ] || [ -z "${REPO_PASSWORD:-}" ]; then
  echo "REPO_USERNAME / REPO_PASSWORD must be set for remote deploy" >&2
  exit 1
fi

xml_escape() {
  local s="$1"
  s="${s//&/\&amp;}"
  s="${s//</\&lt;}"
  s="${s//>/\&gt;}"
  s="${s//\"/\&quot;}"
  printf '%s' "$s"
}

U="$(xml_escape "$REPO_USERNAME")"
P="$(xml_escape "$REPO_PASSWORD")"

# Temporary settings file holding the server credentials; 0600 by default.
TMP_SETTINGS="$(mktemp "${TMPDIR:-/tmp}/maven-settings.XXXXXX")"
# deploy-file resolves the *current* Maven project's POM from the remote repo.
# Launched from this project root that project is libusb4java, so on a first
# deploy the (not-yet-present) POM 404s and the deploy fails. Run deploy-file
# from a directory with no pom.xml so there is no current project and only the
# explicitly-named artifacts are uploaded.
NEUTRAL="$(mktemp -d "${TMPDIR:-/tmp}/deploy-file.XXXXXX")"
trap 'rm -f "$TMP_SETTINGS"; rm -rf "$NEUTRAL"' EXIT
ROOT="$(pwd)"
POM_ABS="$ROOT/$POM"
cd "$NEUTRAL"
cat > "$TMP_SETTINGS" <<EOF
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0">
  <servers>
    <server>
      <id>${REPO_ID}</id>
      <username>${U}</username>
      <password>${P}</password>
    </server>
  </servers>
</settings>
EOF

# 4b) The releases repository is immutable: it has no DELETE and re-PUTting an
# existing artifact returns 400. deploy-file (re)generates the .md5/.sha1 for
# every artifact it uploads, so to refresh a stale checksum the artifact (and
# its .md5/.sha1/.asc) must be deleted first, then this script re-deploys it.
REPO_BASE="${REPO_URL%/}/$(printf '%s' "$GROUP_ID" | tr '.' '/')/$ARTIFACT_ID/$VERSION"
remote_exists() { [ "$(curl -s -o /dev/null -w '%{http_code}' "$1")" = "200" ]; }

require_absent() {
  # $1 = artifact base URL (no extension); $2 = display name.
  if remote_exists "$1"; then
    echo "ERROR: $2 already exists in the immutable repo." >&2
    echo "       Delete $2 (and its .md5/.sha1/.asc) from the repo, then re-run." >&2
    exit 1
  fi
}

# 5) Deploy the POM (+ signature side artifact) to the remote repository
POM_URL="$REPO_BASE/$ARTIFACT_ID-$VERSION.pom"
require_absent "$POM_URL" "$ARTIFACT_ID-$VERSION.pom"
mvn -q -s "$TMP_SETTINGS" deploy:deploy-file \
  -Dfile="$POM_ABS" \
  -DgroupId="$GROUP_ID" \
  -DartifactId="$ARTIFACT_ID" \
  -Dversion="$VERSION" \
  -Dpackaging=pom \
  -Dfiles="${POM_ABS}.asc" \
  -Dtypes=pom.asc \
  -Dclassifiers= \
  -Durl="$REPO_URL" \
  -DrepositoryId="$REPO_ID"
echo "deployed: $ARTIFACT_ID-$VERSION.pom"

# 6) Deploy each platform JAR (+ signature side artifact) under its classifier
for c in "${CLASSIFIERS[@]}"; do
  f="$ROOT/$DIR/libusb4java-$VERSION-$c.jar"
  JAR_URL="$REPO_BASE/$ARTIFACT_ID-$VERSION-$c.jar"
  require_absent "$JAR_URL" "$ARTIFACT_ID-$VERSION-$c.jar"
  mvn -q -s "$TMP_SETTINGS" deploy:deploy-file \
    -Dfile="$f" \
    -DgroupId="$GROUP_ID" \
    -DartifactId="$ARTIFACT_ID" \
    -Dversion="$VERSION" \
    -Dpackaging=jar \
    -Dclassifier="$c" \
    -DgeneratePom=false \
    -Dfiles="$f.asc" \
    -Dtypes=jar.asc \
    -Dclassifiers="$c" \
    -Durl="$REPO_URL" \
    -DrepositoryId="$REPO_ID"
  echo "deployed: libusb4java-$VERSION-$c"
done

echo "Done: deployed libusb4java $VERSION (pom + ${#CLASSIFIERS[@]} classifiers) to repo id=${REPO_ID}"
