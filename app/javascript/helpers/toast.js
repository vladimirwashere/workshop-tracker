/**
 * Show a temporary toast notification instead of a blocking alert().
 * @param {string} message - Text to display
 * @param {"error"|"success"|"info"} type - Visual style
 * @param {number} duration - Auto-dismiss in ms (default 4000)
 */
export function showToast(message, type = "error", duration = 4000) {
  const colors = {
    error:   "bg-red-50/90 border-red-200/50 text-red-700",
    success: "bg-green-50/90 border-green-200/50 text-green-700",
    info:    "bg-blue-50/90 border-blue-200/50 text-blue-700"
  }

  const toast = document.createElement("div")
  toast.className = `fixed bottom-4 right-4 z-50 max-w-sm backdrop-blur-sm border rounded-xl p-4 shadow-lg text-sm transition-opacity duration-300 ${colors[type] || colors.error}`
  toast.textContent = message
  toast.setAttribute("role", "alert")

  document.body.appendChild(toast)

  setTimeout(() => {
    toast.classList.add("opacity-0")
    setTimeout(() => toast.remove(), 300)
  }, duration)
}
