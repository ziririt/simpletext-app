# Skyblue Note Pro 아이콘 v2: B안 색 + 뭉게구름 + 구름 밑 글줄 + 우측 상단 PRO
C = [(-269,-90,115),(-99,-230,170),(121,-175,145),(274,-80,110)]
def cloud(fill, extra=""):
    g = f'<g {extra} fill="{fill}">'
    for x,y,r in C: g += f'<circle cx="{x}" cy="{y}" r="{r}"/>'
    # 바닥: 일자로 두되 양 끝을 둥글게 (옛 아이콘의 각진 '식빵 밑동' 제거)
    g += '<rect x="-372" y="-150" width="752" height="180" rx="88"/>'
    g += '<rect x="-260" y="-160" width="500" height="170"/>'
    return g + '</g>'
def svg(cx=509, cy=610, s=1.0):
    T = f'translate({cx},{cy}) scale({s})'
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
<defs>
 <linearGradient id="sky" x1="0" y1="0" x2="0.35" y2="1"><stop offset="0" stop-color="#0A2A66"/><stop offset="0.6" stop-color="#1E5BC6"/><stop offset="1" stop-color="#5FB4F5"/></linearGradient>
 <radialGradient id="glow" cx="0.82" cy="0.88" r="0.5"><stop offset="0" stop-color="#BFE6FF" stop-opacity="0.45"/><stop offset="1" stop-color="#BFE6FF" stop-opacity="0"/></radialGradient>
 <linearGradient id="cl" x1="0" y1="-400" x2="0" y2="40" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.55" stop-color="#F7FBFF"/><stop offset="1" stop-color="#D9ECFF"/></linearGradient>
 <radialGradient id="hl" cx="0.35" cy="0.25" r="0.6"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.9"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></radialGradient>
 <clipPath id="cc">'+cloud("#000")+'</clipPath>
 <filter id="sh" x="-30%" y="-30%" width="160%" height="170%"><feGaussianBlur stdDeviation="26"/></filter>
 <filter id="ps" x="-20%" y="-40%" width="140%" height="200%"><feDropShadow dx="0" dy="6" stdDeviation="10" flood-color="#04163A" flood-opacity="0.35"/></filter>
</defs>
<rect width="1024" height="1024" fill="url(#sky)"/>
<rect width="1024" height="1024" fill="url(#glow)"/>
<g transform="translate({cx},{cy+34}) scale({s})">{cloud("#04163A", 'opacity="0.30" filter="url(#sh)"')}</g>
<g transform="{T}">{cloud("url(#cl)")}<g clip-path="url(#cc)"><ellipse cx="-150" cy="-260" rx="260" ry="150" fill="url(#hl)"/></g></g>
<rect x="272" y="712" width="480" height="36" rx="18" fill="#FFFFFF" opacity="0.95"/>
<rect x="322" y="780" width="380" height="36" rx="18" fill="#FFFFFF" opacity="0.62"/>
<rect x="387" y="848" width="250" height="36" rx="18" fill="#FFFFFF" opacity="0.38"/>
<g filter="url(#ps)">
 <rect x="556" y="68" width="380" height="162" rx="81" fill="#F3E7C9"/>
 <text x="746" y="182" text-anchor="middle" font-family="Poppins" font-weight="700" font-size="110" letter-spacing="8" fill="#0A2A66">PRO</text>
</g>
</svg>'''
open("icon_v2.svg","w").write(svg())
