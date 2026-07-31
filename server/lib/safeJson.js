/// Safe JSON parsing utility.
///
/// AI models sometimes wrap their JSON responses in markdown code blocks
/// or add extra prose. This utility attempts to extract and parse valid
/// JSON from such responses, falling back to a default value on failure.

/// Parses a JSON string safely, handling common AI response formatting issues.
///
/// Strips markdown code fences (```json ... ```) and attempts to parse
/// the result as JSON. If parsing fails, returns the fallback value.
///
/// @param {string} raw - Raw response string from AI model
/// @param {*} fallback - Value to return if parsing fails
/// @returns {*} Parsed JSON object or fallback value
export function parseJsonSafely(raw, fallback) {
  try {
    const cleaned = raw.trim().replace(/^```json/i, '').replace(/^```/, '').replace(/```$/, '');
    return JSON.parse(cleaned);
  } catch {
    console.error('Failed to parse model response as JSON:', raw);
    return fallback;
  }
}