/// Wraps an async Express handler so rejected promises become 500
/// responses instead of unhandled rejections that can crash the process.
/// Express 4 does not catch errors thrown from async route handlers.

export function asyncHandler(fn) {
  return (req, res) => {
    Promise.resolve(fn(req, res)).catch((err) => {
      console.error('Unhandled error in route:', err);
      if (!res.headersSent) res.status(500).json({ error: 'Internal server error' });
    });
  };
}
