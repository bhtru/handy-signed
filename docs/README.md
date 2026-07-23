# Handy Documentation Hub

Welcome to the central documentation hub for **Handy** (`handy-signed`). This directory contains comprehensive documentation for internal team members, internal AI coding assistants, and end users.

---

## Documentation Structure & Directory Index

| Document | Audience | Description |
|---|---|---|
| [AGENTS.md](file:///Users/brandontruong/Documents/Personal/handy-signed/AGENTS.md) | AI Agents / Developers | AI agent guidelines, core codebase layout, CLI commands, and code conventions. |
| [docs/FEATURES.md](file:///Users/brandontruong/Documents/Personal/handy-signed/docs/FEATURES.md) | Team / AI / Users | Complete feature matrix, implementation status, permission requirements, and roadmap. |
| [docs/TESTING.md](file:///Users/brandontruong/Documents/Personal/handy-signed/docs/TESTING.md) | Team / AI / QA | Unit testing harness, test suite coverage, CI integration, and manual QA guidelines. |
| [docs/RELEASES_AND_DEPLOYMENT.md](file:///Users/brandontruong/Documents/Personal/handy-signed/docs/RELEASES_AND_DEPLOYMENT.md) | DevOps / Maintainers | Status of signed releases, EdDSA Sparkle feed, Developer ID signing, Notarization, and `release.sh` pipeline. |
| [docs/USER_GUIDE.md](file:///Users/brandontruong/Documents/Personal/handy-signed/docs/USER_GUIDE.md) | End-Users | Installation walkthrough, permission grant guide, feature usage manual, and troubleshooting. |
| [docs/ARCHITECTURE.md](file:///Users/brandontruong/Documents/Personal/handy-signed/docs/ARCHITECTURE.md) | Team / AI Architects | Technical system architecture, `CGEventTap` design, AppleScript serialization, FinderSync extension IPC, and `build.sh` internals. |

---

## Repository Overview

- **Repository**: `IsaacYeung/Handy` (`handy-signed`)
- **Target Platform**: macOS 13.0 (Ventura) or later
- **Primary Languages**: Swift (native app & extension), JavaScript/TypeScript (Astro website)
- **Build System**: Custom bash build script ([build.sh](file:///Users/brandontruong/Documents/Personal/handy-signed/build.sh)) using `swiftc` directly (no Xcode project)
- **Update Engine**: Sparkle framework (EdDSA key signed, hosted via GitHub Releases appcast)
- **Latest Production Release**: Version `1.0.0` (tracked in [VERSION](file:///Users/brandontruong/Documents/Personal/handy-signed/VERSION))

---

## Key Workflows Quick Reference

### 1. Verify Code & Run Tests
```bash
bash build.sh --check
```

### 2. Build Installer DMG Locally
```bash
bash build.sh
```

### 3. Deploy Signed & Notarized Release
```bash
SIGNING_IDENTITY="3E901352041D52C4625F6D37ADEEAD3A6AD00CBA" \
NOTARY_PROFILE=handy-notary-tsuga \
NOTARIZE=1 \
bash release.sh
```

### 4. Astro Marketing Site Local Dev Server
```bash
npm run dev
```
