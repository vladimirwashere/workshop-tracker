# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| main    | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly.

**Do NOT open a public GitHub issue for security vulnerabilities.**

### How to Report

1. Email the maintainer at the address listed in the repository owner's GitHub profile.
2. Include a detailed description of the vulnerability, steps to reproduce, and the potential impact.
3. Allow reasonable time for a fix before public disclosure (typically 90 days).

### What to Expect

- **Acknowledgment:** We will acknowledge receipt of your report within 48 hours.
- **Assessment:** We will assess the report and provide an initial response within 5 business days.
- **Fix timeline:** Critical vulnerabilities will be patched as soon as possible. Non-critical issues will be addressed in the next scheduled release.
- **Credit:** We will credit reporters in release notes (unless anonymity is requested).

## Security Practices

This project follows these security practices:

- **Authentication:** bcrypt password hashing with `has_secure_password`
- **Password policy:** Minimum 8 characters, requires uppercase, lowercase, and digit. Reuse of last 5 passwords prevented via `PasswordHistory`
- **Authorization:** Pundit deny-by-default policies with `verify_authorized` and `verify_policy_scoped` enforcement
- **Session management:** Time-bounded sessions (24-hour expiry), concurrent session limits (max 5 per user), IP tracking, automatic cleanup via `CleanupExpiredSessionsJob`
- **Encryption:** Active Record Encryption for PII (email addresses, deterministic mode)
- **Cookie security:** HTTP-only, Secure, SameSite=Lax
- **Input validation:** Strong parameters, model validations, SQL injection prevention
- **Web security:** Content Security Policy, SSL enforcement, CSRF protection, security headers
- **Audit logging:** All data mutations logged with user attribution, IP address, and change snapshots via `AuditLog`
- **Failed login tracking:** Failed authentication attempts are audit-logged
- **Rate limiting:** Rack::Attack throttles (300 req/5min general, 10 login attempts/15min, 5 password resets/hr)
- **Error tracking:** Honeybadger for production error and CSP violation reporting
- **CI/CD:** Brakeman static analysis, bundler-audit, gitleaks secret scanning
- **Dependencies:** Automated Dependabot updates, importmap audit

## Dependencies

Security updates for dependencies are monitored via:
- `bundler-audit` (Ruby gems)
- GitHub Dependabot (gems and GitHub Actions)
- `bin/importmap audit` (JavaScript dependencies)
