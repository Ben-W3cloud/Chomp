/// JWT Authentication Middleware
///
/// Verifies the session token from the Authorization header.
/// Extracts the user ID from the token and attaches it to the request.
///
/// Usage: Apply to routes that require authentication:
///   router.get('/protected', requireAuth, handler)

import jwt from 'jsonwebtoken';

/// Middleware that requires a valid session token.
///
/// Expects the token in the Authorization header as:
///   Authorization: Bearer <token>
///
/// On success, attaches `req.userId` to the request.
/// On failure, returns 401 Unauthorized.
export function requireAuth(req, res, next) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing authorization token' });
  }

  const token = header.slice(7);
  try {
    const payload = jwt.verify(token, process.env.SESSION_JWT_SECRET);
    req.userId = payload.sub; // user ID from JWT subject claim
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}