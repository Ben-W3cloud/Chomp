/// Rate limiting middleware.
///
/// Protects the API from abuse by limiting the number of requests
/// per IP address within a time window.
///
/// - General API: 100 requests per 15 minutes per IP
/// - Auth endpoints: 10 requests per 15 minutes per IP
/// - Scan endpoints: 20 requests per hour per IP

import rateLimit from 'express-rate-limit';

/// General API rate limiter.
/// Applied to all routes by default.
export const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: { error: 'Too many requests. Please slow down.' },
  standardHeaders: true,
  legacyHeaders: false,
});

/// Stricter rate limiter for auth endpoints.
/// Prevents brute force attempts on OAuth exchange.
export const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: { error: 'Too many auth attempts. Please try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
});

/// Moderate rate limiter for scan endpoints.
/// Prevents abuse of the AI-powered scanning pipeline.
export const scanLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 20,
  message: { error: 'Scan limit reached. Please wait before scanning again.' },
  standardHeaders: true,
  legacyHeaders: false,
});