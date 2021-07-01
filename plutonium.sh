#!/bin/sh

# This patch script is for use with the felddy/foundryvtt Docker container.
# See: https://github.com/felddy/foundryvtt-docker#readme

# Installs the Plutonium module if it is not yet installed, and then patches the
# Foundry server to call the Plutonium backend.

MAIN_JS="${FOUNDRY_HOME}/resources/app/main.js"
MODULE_BACKEND_JS="/data/Data/modules/plutonium/server/${FOUNDRY_VERSION:0:3}.x/plutonium-backend.js"
MODULE_DIR="/data/Data/modules"
MODULE_URL="https://get.5e.tools/plutonium/plutonium.zip"
MODULE_DOC_URL="https://wiki.5e.tools/index.php/FoundryTool_Install"
SUPPORTED_VERSIONS="0.6.5 0.6.6 0.7.1 0.7.2 0.7.3 0.7.4 0.7.5 0.7.6 0.7.7 0.7.8 0.7.9 0.7.10"
WORKDIR=$(mktemp -d)
ZIP_FILE="${WORKDIR}/plutonium.zip"

log "Installing Plutonium module and backend."
log "See: ${MODULE_DOC_URL}"
if [ -z "${SUPPORTED_VERSIONS##*$FOUNDRY_VERSION*}" ] ; then
  log "This patch has been tested with Foundry Virtual Tabletop ${FOUNDRY_VERSION}"
else
  log_warn "This patch has not been tested with Foundry Virtual Tabletop ${FOUNDRY_VERSION}"
fi
if [ ! -f $MODULE_BACKEND_JS ]; then
  log "Downloading Plutonium module."
  curl --output "${ZIP_FILE}" "${MODULE_URL}" 2>&1 | tr "\r" "\n"
  log "Ensuring module directory exists."
  mkdir -p "${MODULE_DIR}"
  log "Installing Plutonium module."
  unzip -o "${ZIP_FILE}" -d "${MODULE_DIR}"
fi
log "Installing Plutonium backend."
cp "${MODULE_BACKEND_JS}" "${FOUNDRY_HOME}/resources/app/"
log "Patching main.js to use plutonium-backend."
sed --file=- --in-place=.orig ${MAIN_JS} << SED_SCRIPT
s/^\(require(\"init\").*\);\
/\1.then(() => {require(\"plutonium-backend\").init();});/g\
w plutonium_patchlog.txt
SED_SCRIPT
if [ -s plutonium_patchlog.txt ]; then
  log "Plutonium backend patch was applied successfully."
  log "Plutonium art and media tools will be enabled."
else
  log_error "Plutonium backend patch could not be applied."
  log_error "main.js did not contain the expected source lines."
  log_warn "Foundry Virtual Tabletop will still operate without the art and media tools enabled."
  log_warn "Update this patch file to a version that supports Foundry Virtual Tabletop ${FOUNDRY_VERSION}."
fi
log "Cleaning up."
rm -r ${WORKDIR}
