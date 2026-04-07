# Tools

## Comparative research

- `tavily_search` — find existing articles on the same topic to
  evaluate originality. If the draft's argument already exists in
  three well-known posts, the author should either cite them and
  build on them, or have a genuinely new angle.
- `web_fetch` — read comparison articles in full to judge whether the
  draft actually adds something.

## Argument-checking

- `tavily_search` with `search_depth: "advanced"` and
  `include_answer: true` — find counter-arguments to the article's
  thesis. If the draft ignores well-known objections, flag that.

## Originality check pattern

When the article makes a novel-sounding claim:

```
tavily_search({
  query: "<claim in quotes or paraphrased>",
  search_depth: "advanced",
  max_results: 10,
})
```

If the search returns 10+ articles making the same claim, the
draft's framing ("I've noticed that...") is misleading — the
author should acknowledge the existing discourse.

## What you don't need

- `web_fetch` for the article itself — you already have the draft
  content from the spawning agent.
- Code-specific tools — that's `articles-code`'s domain.
- Fact-verification tools for individual claims — that's
  `articles-facts`. You critique at a higher level (is the argument
  sound?) rather than checking individual claims.
