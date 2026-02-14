// Shared date formatter: DD/MM/YY
export function formatDate(date) {
  const d = new Date(date)
  return `${String(d.getDate()).padStart(2, "0")}/${String(d.getMonth() + 1).padStart(2, "0")}/${String(d.getFullYear()).slice(-2)}`
}
