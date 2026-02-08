/**
 * JWT Authentication
 *
 * Handles JWT token creation, verification, and extraction
 */

import jwt from 'jsonwebtoken';
import type { IncomingMessage } from 'http';
import type { AuthUser } from '../types.js';

const JWT_SECRET = process.env.JWT_SECRET || 'wp-praxis-secret-change-in-production';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '24h';

export function extractToken(req: IncomingMessage): string | null {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    return null;
  }

  // Support "Bearer <token>" format
  if (authHeader.startsWith('Bearer ')) {
    return authHeader.substring(7);
  }

  return authHeader;
}

export async function verifyToken(token: string): Promise<AuthUser | null> {
  try {
    const decoded = jwt.verify(token, JWT_SECRET) as any;

    return {
      id: decoded.id || decoded.sub,
      username: decoded.username,
      roles: decoded.roles || [],
      permissions: decoded.permissions || [],
    };
  } catch (error) {
    return null;
  }
}

export function generateToken(user: AuthUser): string {
  return jwt.sign(
    {
      sub: user.id,
      username: user.username,
      roles: user.roles,
      permissions: user.permissions,
    },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRES_IN }
  );
}
