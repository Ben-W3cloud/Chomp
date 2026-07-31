export function parseJsonSafely(raw, fallback) {
  try {
    const cleaned = raw.trim().replace(/^```json/i, '').replace(/^```/, '').replace(/```$/, '');
    return JSON.parse(cleaned);
  } catch {
    console.error('Failed to parse model response as JSON:', raw);
    return fallback;
  }
}