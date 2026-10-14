/*
 * FFI compatibility shim for the jyotish Dart package.
 * The upstream API is char *swe_version(char *buffer), while the Dart binding
 * incorrectly declares char *swe_version(void). Build upstream sources with
 * -Dswe_version=swe_version_buffer and compile this file without that define.
 */
extern char *swe_version_buffer(char *buffer);

char *swe_version(void) {
  static char version[32];
  return swe_version_buffer(version);
}
