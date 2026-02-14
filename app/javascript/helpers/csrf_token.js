/**
 * Get the CSRF token from the meta tag.
 * @returns {string|undefined}
 */
export function csrfToken() {
  return document.querySelector('meta[name="csrf-token"]')?.content
}
