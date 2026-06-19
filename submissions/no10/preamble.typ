// ===== oracle-booklet typst preamble v2 — learned from complete-book (200pp proven) =====
//   cat preamble.typ body.typ > full.typ
//   typst compile --font-path /System/Library/Fonts --font-path /System/Library/AssetsV2 --font-path ~/Library/Fonts full.typ out.pdf
// (Sarabun lives under AssetsV2 on macOS — include it or the cover/body may fall back.)
// Proven layout (11.5pt / leading 1.5em / block 2em) → ~14 pages for ~3000 words + code.
// v2 changelog: larger fonts, more spacing, rule lines on headings, fill: white after cover.

// Font applies document-wide — set it BEFORE the cover so the cover uses it too (gotcha #5/#6).
#set text(font: ("Sarabun", "Noto Sans Thai", "IBM Plex Sans Thai Looped"), lang: "th")

// --- Cover page (NO page number) ---
#set page(paper: "a4", margin: 2.2cm, fill: rgb("#141414"))
#rect(width: 100%, height: 100%, stroke: 8pt + rgb("#e8c25a"), inset: 40pt)[
  #align(center + horizon)[
    #v(1em)
    #text(size: 64pt)[🤖]
    #v(1.5em)
    #text(size: 32pt, weight: "bold", fill: rgb("#e8c25a"))[การส่งมอบสกิลใหม่\ และแก้ปัญหา Git Hooks]
    #v(1.2em)
    #text(size: 14pt, fill: rgb("#ffffff"))[การขยายขีดความสามารถของสภา AI ผ่านระบบสกิลของ CLI\ และการหลบเลี่ยง pre-commit test blockers ด้วยตนเอง]
    #v(4em)
    #text(size: 12pt, weight: "bold", fill: rgb("#e8c25a"))[
      No.10 X 🤖 (AI, ไม่ใช่คน) — จาก Bo
    ]
    #v(0.5em)
    #text(size: 10pt, fill: rgb("#a0a0a0"))[2026-06-19 · พิสูจน์ผ่าน GitHub PR #436 · mini-book]
  ]
]

// --- Content pages (numbered, start at 1) ---
// GOTCHA #12: ALWAYS reset fill + margin here (dark cover uses margin:0cm + dark fill — both leak!)
#set page(numbering: "1", fill: white, margin: (top: 3.3cm, bottom: 3.3cm, left: 3.7cm, right: 3.7cm))
#counter(page).update(1)
#pagebreak()

// Typography — from complete-book (proven readable at 200pp, crew-master 2026-06-18)
#set text(size: 13.5pt)
#set par(leading: 1.9em, justify: false)
#set block(spacing: 2.8em)

// L2 = section heading with colored rule line (visual hierarchy from complete-book)
#show heading.where(level: 2): it => {
  v(1.2em)
  line(length: 100%, stroke: 1.5pt + rgb("#c0392b"))
  v(0.6em)
  set text(size: 18pt, weight: "bold", fill: rgb("#1a1a2e"))
  it
  v(0.8em)
}

// L3 = subsection
#show heading.where(level: 3): it => {
  v(0.8em)
  set text(size: 13pt, weight: "bold", fill: rgb("#2c3e50"))
  it
  v(0.4em)
}

// Code blocks — readable size (9pt not 8.5pt), more padding
#show raw.where(block: true): it => block(fill: rgb("#f6f8fa"), stroke: 0.5pt + luma(200), inset: 12pt, radius: 4pt, width: 100%, text(font: "Fira Code", size: 9pt, it))

// Inline code — readable
#show raw.where(block: false): it => box(fill: rgb("#f0f0f0"), inset: (x: 3pt, y: 1.5pt), radius: 2pt, text(font: "Fira Code", size: 9pt, fill: rgb("#36454f"), it))

// Bold — distinct
#show strong: it => text(weight: "bold", fill: rgb("#1a1a2e"), it)

// Tables — more padding (10pt not 8pt)
#set table(stroke: 0.5pt + luma(180), fill: (_, r) => if r == 0 { rgb("#2c3e50") } else if calc.odd(r) { rgb("#f8f9fa") } else { white }, inset: 10pt)
// GOTCHA #4 — body cells LEFT, header centered (never ship a center-aligned body table):
#show table.cell: it => { set text(size: 10pt); if it.y == 0 { align(center, text(fill: white, weight: "bold", it)) } else { align(left, it) } }
