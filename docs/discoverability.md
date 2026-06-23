# GitHub discoverability — decisa-swift

Use this page when configuring the repository on GitHub. The README is the primary
SEO surface; these fields reinforce discoverability in GitHub search and topic
browsing.

## About (repository description)

Paste into **Settings → General → Description** (max ~350 characters):

```
Native iOS attribution SDK (Swift Package Manager) for Decisa — paid ads, web2app & funnel2app install matching, deferred deep linking, and in-app conversion tracking via /v1/resolve, /v1/identify, /v1/track. No ATT/IDFA in v1.
```

Shorter alternative (~160 characters):

```
iOS attribution SDK (SPM) for Decisa — web2app & funnel2app, deferred deep links, conversion tracking. Swift Package Manager. Public pixel_key only.
```

## Website

If you have a product/docs URL, set **Settings → General → Website** to your
Decisa docs or landing page (e.g. `https://decisa.ai`).

## Topics (full list)

Add under **Settings → General → Topics** (GitHub allows up to 20):

| Topic | Rationale |
| --- | --- |
| `ios` | Platform |
| `swift` | Language |
| `swift-package-manager` | Primary distribution |
| `spm` | Common abbreviation developers search |
| `mobile-attribution` | Core category |
| `attribution` | Broad discoverability |
| `ad-attribution` | Paid ads use case |
| `mobile-ads` | Ad buyer / growth engineer audience |
| `conversion-tracking` | Event tracking intent |
| `web2app` | Web-to-app funnel keyword |
| `funnel2app` | Funnel-to-app keyword |
| `deferred-deep-linking` | Install attribution mechanism |
| `apple-search-ads` | AdServices enrichment |
| `adservices` | iOS API surface |
| `capi` | Server-side conversion API adjacency |
| `mcp` | Decisa MCP ecosystem |
| `first-party-data` | Privacy-forward positioning |
| `sdk` | Generic SDK discovery |
| `skadnetwork` | Adjacent search (SKAdNetwork-aware buyers; SDK does not replace SKAN) |
| `swiftui` | Common integration context |

## Social preview

GitHub uses the README opening paragraphs as the repository card description.
Keep the H1 and first two paragraphs stable — they double as the de facto meta
description for link previews.

## Related repositories

Cross-link from org profile and sibling READMEs:

- [decisa-flutter](https://github.com/decisa-ai/decisa-flutter) — Flutter mobile SDK (iOS + Android)
- Decisa MCP server — campaign & attribution ops for agents (link when public)

## Changelog discoverability

When releasing, mention searchable terms in GitHub Release notes (not just version
numbers): *iOS attribution*, *Swift Package Manager*, *web2app*, *deferred deep
linking*, *conversion tracking*.
