#!/bin/sh
# clean up any previous products/symbolic links in the Internet Plug-Ins folder
if [ -a "${USER_LIBRARY_DIR}/Internet Plug-Ins/${FULL_PRODUCT_NAME}" ]; then
  rm -Rf "${USER_LIBRARY_DIR}/Internet Plug-Ins/${FULL_PRODUCT_NAME}"
fi

# Depending on the build configuration, either copy or link to the most recent product
if [ "${CONFIGURATION}" == "Debug" ]; then
  # if we're debugging, add a symbolic link to the plug-in
  ln -sf "${TARGET_BUILD_DIR}/${FULL_PRODUCT_NAME}" \
    "${USER_LIBRARY_DIR}/Internet Plug-Ins/${FULL_PRODUCT_NAME}"
elif [ "${CONFIGURATION}" == "Release" ]; then
  # if we're compiling for release, just copy the plugin to the Internet Plug-ins folder
  cp -Rfv "${TARGET_BUILD_DIR}/${FULL_PRODUCT_NAME}" \
    "${USER_LIBRARY_DIR}/Internet Plug-Ins/${FULL_PRODUCT_NAME}"
fi
