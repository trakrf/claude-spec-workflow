# Feature: JWT Authentication System

## Metadata
**Workspace**: backend
**Type**: feature

## Outcome
Users can securely authenticate with the API using JWT tokens, with automatic token refresh and proper session management.

## User Story
As an API user
I want to authenticate with email/password and receive a JWT token
So that I can make authorized requests without sending credentials repeatedly

## Context
**Current**: No authentication system exists. API endpoints are currently open.
**Desired**: Secure JWT-based authentication with refresh tokens and proper session handling.
**Examples**:
- Similar pattern in `examples/` (reference your own codebase)
- Auth0 JWT structure for token format
- Express middleware pattern for route protection

## Technical Requirements
- JWT tokens with 15-minute expiration
- Refresh tokens with 7-day expiration stored in httpOnly cookies
- POST /api/auth/login endpoint (email, password)
- POST /api/auth/refresh endpoint (refresh token)
- POST /api/auth/logout endpoint (invalidate tokens)
- Middleware to protect routes requiring authentication
- Password hashing with bcrypt (12 rounds)
- Token blacklist for logout (Redis or in-memory for MVP)
- Rate limiting on auth endpoints (5 attempts per 15 minutes)

## Validation Criteria
- [ ] User can login with valid credentials and receive access + refresh tokens
- [ ] Invalid credentials return 401 with appropriate error message
- [ ] Protected routes reject requests without valid JWT
- [ ] Expired access tokens can be refreshed with valid refresh token
- [ ] Logout invalidates both access and refresh tokens
- [ ] Password is never stored in plain text
- [ ] Rate limiting blocks brute force attempts
- [ ] All auth endpoints have proper error handling and logging

## References
- JWT Best Practices: https://datatracker.ietf.org/doc/html/rfc8725
- OWASP Auth Cheatsheet: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
- Existing user model: `src/models/User.ts` (if it exists)
- Express middleware pattern: `src/middleware/errorHandler.ts`
