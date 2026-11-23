// 生成 10 门 AI 微课的课程封面（SVG 海报），输出到 public/ai/01.svg ~ 10.svg
// 用法：node scripts/gen-ai-covers.mjs
import { mkdirSync, writeFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const OUT_DIR = join(__dirname, '..', 'public', 'ai')

const W = 800
const H = 450

const lessons = [
  {
    n: 1,
    lines: ['人工智能的现状', '趋势与战略'],
    en: 'STATUS · TRENDS · STRATEGY',
    c1: '#0b2a6b', c2: '#1d4ed8', accent: '#60a5fa',
    motif: bars(),
  },
  {
    n: 2,
    lines: ['机器眼中的', '大千世界'],
    en: 'COMPUTER VISION',
    c1: '#2a1a6b', c2: '#7c3aed', accent: '#c4b5fd',
    motif: eye(),
  },
  {
    n: 3,
    lines: ['语言与机器的', '火花碰撞'],
    en: 'NATURAL LANGUAGE PROCESSING',
    c1: '#05414a', c2: '#0e7490', accent: '#67e8f9',
    motif: bubbles(),
  },
  {
    n: 4,
    lines: ['认知科学与', 'AI 世界的邀约'],
    en: 'COGNITION & REASONING',
    c1: '#3b0764', c2: '#9d174d', accent: '#f9a8d4',
    motif: graph(),
  },
  {
    n: 5,
    lines: ['机器自我', '成长进步'],
    en: 'MACHINE LEARNING',
    c1: '#0c2d6b', c2: '#0e7490', accent: '#7dd3fc',
    motif: curve(),
  },
  {
    n: 6,
    lines: ['未来生活', '离不开的伙伴'],
    en: 'INTELLIGENT ROBOTICS',
    c1: '#08304e', c2: '#0369a1', accent: '#93c5fd',
    motif: robot(),
  },
  {
    n: 7,
    lines: ['机器世界', '不孤单'],
    en: 'MULTI-AGENT SYSTEMS',
    c1: '#241a72', c2: '#4f46e5', accent: '#a5b4fc',
    motif: agents(),
  },
  {
    n: 8,
    lines: ['机器生活的世界', '物理世界仿真'],
    en: 'SIMULATION & DIGITAL TWIN',
    c1: '#053f3a', c2: '#0d9488', accent: '#5eead4',
    motif: cube(),
  },
  {
    n: 9,
    lines: ['舞动科技的', '音符'],
    en: 'ARTIFICIAL INTELLIGENCE & MUSIC',
    c1: '#5b2107', c2: '#c2620a', accent: '#fcd34d',
    motif: music(),
  },
  {
    n: 10,
    lines: ['人工智能', '在北大'],
    en: 'AI AT PEKING UNIVERSITY',
    c1: '#5c0d0d', c2: '#b91c1c', accent: '#fbbf24',
    motif: campus(),
  },
]

function bars() {
  const xs = [520, 566, 612, 658, 704]
  const hs = [42, 70, 58, 104, 132]
  const bars = xs
    .map((x, i) => `<rect x="${x}" y="${330 - hs[i]}" width="28" height="${hs[i]}" rx="6" fill="url(#bar)" opacity="${0.5 + i * 0.12}"/>`)
    .join('')
  return `${bars}
  <path d="M520 300 L580 262 L636 276 L700 200" fill="none" stroke="#fff" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round" opacity=".9"/>
  ${[[520, 300], [580, 262], [636, 276], [700, 200]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="6" fill="#fff"/>`).join('')}
  <circle cx="700" cy="200" r="14" fill="none" stroke="#fff" stroke-width="2" opacity=".45"/>`
}

function eye() {
  return `<path d="M470 225 Q580 120 690 225 Q580 330 470 225 Z" fill="none" stroke="#fff" stroke-width="4" opacity=".9"/>
  <circle cx="580" cy="225" r="52" fill="none" stroke="#fff" stroke-width="4" opacity=".9"/>
  <circle cx="580" cy="225" r="20" fill="#fff" opacity=".9"/>
  ${[0, 1, 2].map((i) => `<path d="M${500 + i * 54} 138 L${470 + i * 60} 104" stroke="#fff" stroke-width="3" opacity=".35"/>`).join('')}
  <rect x="466" y="112" width="230" height="228" rx="14" fill="none" stroke="#fff" stroke-width="2" stroke-dasharray="10 12" opacity=".28"/>
  ${[[466, 112], [696, 112], [466, 340], [696, 340]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="5" fill="#fff" opacity=".8"/>`).join('')}`
}

function bubbles() {
  return `<rect x="468" y="128" width="196" height="104" rx="24" fill="none" stroke="#fff" stroke-width="3.5" opacity=".9"/>
  <path d="M500 232 L500 264 L536 232" fill="none" stroke="#fff" stroke-width="3.5" opacity=".9"/>
  ${[0, 1, 2].map((i) => `<rect x="496" y="${158 + i * 24}" width="${i === 2 ? 96 : 140}" height="8" rx="4" fill="#fff" opacity=".62"/>`).join('')}
  <rect x="586" y="268" width="140" height="76" rx="20" fill="none" stroke="#fff" stroke-width="3" opacity=".55"/>
  ${[0, 1].map((i) => `<rect x="610" y="${294 + i * 24}" width="${i === 1 ? 60 : 92}" height="7" rx="3.5" fill="#fff" opacity=".42"/>`).join('')}
  ${[[700, 150], [722, 190], [706, 232]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="4" fill="#fff" opacity=".8"/>`).join('')}`
}

function graph() {
  const nodes = [[512, 160], [636, 132], [700, 232], [596, 236], [512, 312], [648, 330]]
  const edges = [[0, 3], [1, 3], [3, 2], [3, 4], [2, 5], [4, 5], [0, 1]]
  return `${edges.map(([a, b]) => `<line x1="${nodes[a][0]}" y1="${nodes[a][1]}" x2="${nodes[b][0]}" y2="${nodes[b][1]}" stroke="#fff" stroke-width="2.5" opacity=".32"/>`).join('')}
  ${nodes.map(([x, y], i) => `<circle cx="${x}" cy="${y}" r="${i === 3 ? 15 : 10}" fill="${i === 3 ? '#fff' : 'none'}" stroke="#fff" stroke-width="3" opacity=".92"/>`).join('')}`
}

function curve() {
  return `<path d="M470 330 L730 330" stroke="#fff" stroke-width="2.5" opacity=".28"/>
  <path d="M470 330 L470 128" stroke="#fff" stroke-width="2.5" opacity=".28"/>
  <path d="M470 322 C540 150 600 200 660 246 C692 270 712 286 730 296" fill="none" stroke="#fff" stroke-width="3.5" stroke-linecap="round"/>
  ${[[470, 322], [546, 208], [630, 226], [730, 296]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="7" fill="#fff"/>`).join('')}
  <line x1="546" y1="208" x2="546" y2="330" stroke="#fff" stroke-width="2" stroke-dasharray="6 8" opacity=".4"/>
  <line x1="630" y1="226" x2="630" y2="330" stroke="#fff" stroke-width="2" stroke-dasharray="6 8" opacity=".4"/>`
}

function robot() {
  return `<line x1="580" y1="104" x2="580" y2="132" stroke="#fff" stroke-width="3" opacity=".7"/>
  <circle cx="580" cy="100" r="8" fill="#fff" opacity=".9"/>
  <rect x="486" y="132" width="188" height="150" rx="36" fill="none" stroke="#fff" stroke-width="4" opacity=".92"/>
  <circle cx="536" cy="196" r="15" fill="#fff"/>
  <circle cx="624" cy="196" r="15" fill="#fff"/>
  <path d="M540 242 Q580 266 620 242" fill="none" stroke="#fff" stroke-width="3.5" stroke-linecap="round" opacity=".85"/>
  <rect x="520" y="300" width="120" height="34" rx="12" fill="none" stroke="#fff" stroke-width="3" opacity=".55"/>
  <rect x="446" y="176" width="24" height="62" rx="10" fill="none" stroke="#fff" stroke-width="3" opacity=".45"/>
  <rect x="690" y="176" width="24" height="62" rx="10" fill="none" stroke="#fff" stroke-width="3" opacity=".45"/>`
}

function agents() {
  const pts = [[500, 200], [580, 150], [660, 200], [580, 300]]
  const hex = (cx, cy, r) => {
    const p = Array.from({ length: 6 }, (_, i) => {
      const a = (Math.PI / 3) * i - Math.PI / 2
      return `${(cx + r * Math.cos(a)).toFixed(1)},${(cy + r * Math.sin(a)).toFixed(1)}`
    }).join(' ')
    return `<polygon points="${p}" fill="none" stroke="#fff" stroke-width="3" opacity=".7"/>`
  }
  return `${pts.map(([x, y]) => `<line x1="580" y1="225" x2="${x}" y2="${y}" stroke="#fff" stroke-width="2.5" opacity=".3"/>`).join('')}
  ${pts.map(([x, y]) => hex(x, y, 40) + `<circle cx="${x}" cy="${y}" r="8" fill="#fff"/>`).join('')}
  ${hex(580, 225, 34)}
  <circle cx="580" cy="225" r="10" fill="#fff"/>`
}

function cube() {
  return `<g transform="translate(580 232)">
  <path d="M-90 -30 L0 -78 L90 -30 L0 18 Z" fill="none" stroke="#fff" stroke-width="3.5" opacity=".92"/>
  <path d="M-90 -30 L-90 56 L0 104 L0 18" fill="none" stroke="#fff" stroke-width="3.5" opacity=".92"/>
  <path d="M90 -30 L90 56 L0 104" fill="none" stroke="#fff" stroke-width="3.5" opacity=".92"/>
  <path d="M-90 56 L0 8 L90 56" fill="none" stroke="#fff" stroke-width="2" opacity=".35"/>
  <path d="M-45 -54 L45 -6 M-45 26 L45 74" stroke="#fff" stroke-width="1.5" opacity=".2"/>
  </g>
  <ellipse cx="580" cy="232" rx="150" ry="34" fill="none" stroke="#fff" stroke-width="2" stroke-dasharray="8 10" opacity=".32" transform="rotate(-14 580 232)"/>
  <circle cx="700" cy="168" r="6" fill="#fff" opacity=".9"/>
  <circle cx="452" cy="292" r="6" fill="#fff" opacity=".9"/>`
}

function music() {
  const heights = [26, 48, 76, 106, 78, 132, 96, 62, 88, 44, 66, 30]
  const bars = heights
    .map((h, i) => `<rect x="${486 + i * 20}" y="${250 - h / 2}" width="9" height="${h}" rx="4.5" fill="#fff" opacity="${0.35 + (h / 132) * 0.6}"/>`)
    .join('')
  return `${bars}
  <path d="M660 148 L660 214" stroke="#fff" stroke-width="4" opacity=".85"/>
  <ellipse cx="646" cy="216" rx="16" ry="12" fill="#fff" opacity=".9" transform="rotate(-18 646 216)"/>
  <path d="M660 148 L700 138 L700 172" fill="none" stroke="#fff" stroke-width="4" opacity=".7"/>
  <ellipse cx="686" cy="176" rx="14" ry="10" fill="#fff" opacity=".7" transform="rotate(-18 686 176)"/>`
}

function campus() {
  const cols = [498, 540, 582, 624, 666]
  return `<g opacity=".92">
  <path d="M462 262 L582 198 L702 262 Z" fill="none" stroke="#fff" stroke-width="3.5"/>
  <path d="M462 262 L702 262" stroke="#fff" stroke-width="3.5"/>
  ${cols.map((x) => `<rect x="${x - 9}" y="262" width="18" height="74" fill="none" stroke="#fff" stroke-width="2.5" opacity=".75"/>`).join('')}
  <rect x="474" y="332" width="216" height="10" rx="4" fill="#fff" opacity=".55"/>
  <rect x="492" y="348" width="180" height="8" rx="3" fill="#fff" opacity=".3"/>
  <circle cx="582" cy="230" r="7" fill="#fff" opacity=".85"/>
  </g>
  ${[[700, 150], [726, 186], [700, 222]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="5" fill="#fff" opacity=".7"/>`).join('')}
  <path d="M700 150 L726 186 L700 222" fill="none" stroke="#fff" stroke-width="2" opacity=".3"/>`
}

function esc(s) {
  return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
}

function buildSvg(l) {
  const longest = Math.max(...l.lines.map((s) => s.length))
  const fontSize = longest >= 8 ? 40 : 46
  const lineGap = fontSize + 14
  const startY = l.lines.length === 2 ? 214 - lineGap / 2 : 206
  const title = l.lines
    .map((s, i) => `<text x="58" y="${startY + i * lineGap}" font-family="'Microsoft YaHei','PingFang SC',sans-serif" font-size="${fontSize}" font-weight="700" fill="#ffffff">${esc(s)}</text>`)
    .join('')

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" role="img" aria-label="第${l.n}讲">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="${l.c1}"/>
      <stop offset="1" stop-color="${l.c2}"/>
    </linearGradient>
    <linearGradient id="bar" x1="0" y1="1" x2="0" y2="0">
      <stop offset="0" stop-color="${l.accent}" stop-opacity=".35"/>
      <stop offset="1" stop-color="${l.accent}" stop-opacity=".95"/>
    </linearGradient>
    <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5">
      <stop offset="0" stop-color="${l.accent}" stop-opacity=".42"/>
      <stop offset="1" stop-color="${l.accent}" stop-opacity="0"/>
    </radialGradient>
    <pattern id="grid" width="40" height="40" patternUnits="userSpaceOnUse">
      <path d="M40 0 L0 0 0 40" fill="none" stroke="#ffffff" stroke-opacity=".07" stroke-width="1"/>
    </pattern>
  </defs>

  <rect width="${W}" height="${H}" fill="url(#bg)"/>
  <rect width="${W}" height="${H}" fill="url(#grid)"/>
  <circle cx="620" cy="210" r="260" fill="url(#glow)"/>
  <text x="742" y="410" text-anchor="end" font-family="'Microsoft YaHei',sans-serif" font-size="200" font-weight="700" fill="#ffffff" opacity=".06">${String(l.n).padStart(2, '0')}</text>

  <g>${l.motif}
  </g>

  <rect x="58" y="58" width="126" height="34" rx="17" fill="#ffffff" fill-opacity=".16" stroke="#ffffff" stroke-opacity=".34"/>
  <text x="121" y="81" text-anchor="middle" font-family="'Microsoft YaHei',sans-serif" font-size="17" font-weight="600" fill="#ffffff">第 ${l.n} 讲</text>

  ${title}
  <rect x="58" y="${startY + (l.lines.length - 1) * lineGap + 26}" width="52" height="4" rx="2" fill="${l.accent}"/>
  <text x="58" y="${startY + (l.lines.length - 1) * lineGap + 66}" font-family="'Segoe UI',Arial,sans-serif" font-size="14" letter-spacing="2.6" font-weight="600" fill="#ffffff" fill-opacity=".72">${esc(l.en)}</text>

  <rect x="0" y="440" width="${W}" height="10" fill="${l.accent}" opacity=".85"/>
</svg>
`
}

mkdirSync(OUT_DIR, { recursive: true })
for (const lesson of lessons) {
  const file = join(OUT_DIR, `${String(lesson.n).padStart(2, '0')}.svg`)
  writeFileSync(file, buildSvg(lesson), 'utf8')
  console.log('generated', file)
}
