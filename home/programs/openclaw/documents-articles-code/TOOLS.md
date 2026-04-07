# Tools

## Primary reference tools

- `web_fetch` — retrieve official language docs, specs, RFCs, and
  release notes. This is your main tool for verifying language
  semantics claims.
- `tavily_extract` — use `extract_depth: "advanced"` for JS-heavy
  documentation sites (MDN, TypeScript handbook, etc.) where
  `web_fetch` fails.
- `tavily_search` — finding CVEs, known issues, deprecation notices,
  and relevant RFC numbers. Use `include_domains` to restrict to the
  project's domain when looking for official info.

## Known-good documentation URLs

Keep these as a mental cache; fetch specific sections on demand:

- **Rust**: `https://doc.rust-lang.org/std/` (std), `https://doc.rust-lang.org/reference/` (spec)
- **Python**: `https://docs.python.org/3/` (docs), PEPs at `https://peps.python.org/pep-XXXX/`
- **Go**: `https://pkg.go.dev/` (packages), `https://go.dev/ref/spec` (spec)
- **JS/TS**: MDN at `https://developer.mozilla.org/` (needs `tavily_extract`),
  TypeScript handbook at `https://www.typescriptlang.org/docs/handbook/`
- **Node.js**: `https://nodejs.org/api/` (API docs, versioned)
- **C++**: `https://en.cppreference.com/` (unofficial but authoritative)

## Verification patterns

### Checking a function signature is current

```
web_fetch({
  url: "https://doc.rust-lang.org/std/vec/struct.Vec.html#method.drain",
  extractMode: "markdown"
})
```

Compare the extracted signature to the article's code.

### Checking if a feature is deprecated

```
tavily_search({
  query: "<function_name> deprecated <language>",
  include_domains: ["<project-docs-domain>"],
  search_depth: "advanced",
})
```

### Checking security implications

For code that touches crypto, auth, or network:
```
tavily_search({
  query: "<pattern> CVE OR security vulnerability",
  time_range: "year",
})
```
