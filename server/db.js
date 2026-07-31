/// Database connection pool and query helper.
///
/// Sets up a PostgreSQL connection pool using the `pg` library.
/// Connects to Neon Postgres using the connection string from environment.
/// Provides a simple query helper that manages connection lifecycle.

import pg from 'pg';
import 'dotenv/config';

const { Pool } = pg;

// Create connection pool to Neon Postgres
// SSL is required for Neon connections
export const pool = new Pool({
  connectionString: process.env.NEON_DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

/// Executes a SQL query with parameters.
///
/// Automatically acquires and releases a connection from the pool.
/// Use this for all database queries throughout the server.
///
/// @param {string} text - SQL query with $1, $2, etc. placeholders
/// @param {Array} params - Values to bind to placeholders
/// @returns {Promise<{rows: Array, fields: Array}>} Query result
export async function query(text, params) {
  const client = await pool.connect();
  try {
    return await client.query(text, params);
  } finally {
    client.release();
  }
}