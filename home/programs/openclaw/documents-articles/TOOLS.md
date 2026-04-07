# Tools

## Web tools (for research during drafting)

- `web_search` — find articles, papers, and references via Tavily
- `web_fetch` — retrieve a specific URL and extract readable content
- `tavily_search` — advanced search (domain filters, recency, AI answers)
- `tavily_extract` — extract content from JS-rendered pages when
  `web_fetch` fails

## Content tools

- `summarize` — summarize URLs, PDFs, YouTube videos into drafting
  material

## Subagents (spawned via agent tool)

- `articles-facts` — fact checker
- `articles-code` — code reviewer
- `articles-critic` — editorial critic
- `articles-humanizer` — AI-text detector

## Usage notes

- When referencing a paper or blog post, fetch it with `web_fetch` or
  `tavily_extract` first to get the actual content rather than relying
  on search snippets.
- For code examples in articles, run them through `articles-code` before
  publishing. Broken code in tutorials is worse than no code at all.
