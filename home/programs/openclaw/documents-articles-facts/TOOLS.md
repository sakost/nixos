# Tools

## Primary research tools

- `tavily_search` — use with `search_depth: "advanced"` and
  `include_answer: false` for fact-checking. Set
  `include_domains` to restrict to authoritative sources when
  validating project-specific claims (e.g.,
  `["rust-lang.org", "doc.rust-lang.org"]`).
- `web_fetch` — retrieve a specific URL and extract readable content.
  Use for reading primary sources directly after finding them.
- `tavily_extract` — use `extract_depth: "advanced"` for
  JS-rendered project pages or docs sites that `web_fetch` can't
  handle.

## Fallback tools

- `web_search` — generic search via the configured provider. Use when
  `tavily_search` returns nothing useful and you need a broader net.

## Search patterns

### Verifying a version claim

```
tavily_search({
  query: "<project> <version> changelog",
  include_domains: ["github.com", "<project>.org"],
  search_depth: "advanced",
})
```

Follow up with `web_fetch` on the changelog URL to confirm the exact
version and date.

### Verifying a benchmark claim

```
tavily_search({
  query: "<benchmark name> methodology",
  search_depth: "advanced",
  time_range: "year",
})
```

Look for a paper or blog post with reproducible methodology. If the
only sources are blog posts citing each other, flag as
`unverifiable`.

### Verifying a historical attribution

Always cross-reference at least two primary sources. "X invented Y"
claims are frequently contested, and Wikipedia is often wrong on
attribution specifically. Look for the original paper, talk, or mailing
list post.
