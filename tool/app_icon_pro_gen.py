import sys
def cloud(cx, cy, s, fill, extra=""):
    # 겹친 원과 바닥 둥근사각형으로 구름 모양
    c = [(-150,40,120),(-30,-40,170),(130,10,140),(230,70,95),(-250,90,80)]
    out = f'<g transform="translate({cx},{cy}) scale({s})" fill="{fill}" {extra}>'
    for x,y,r in c: out += f'<circle cx="{x}" cy="{y}" r="{r}"/>'
    out += '<rect x="-330" y="70" width="655" height="100" rx="50"/></g>'
    return out

def icon(v):
    if v=="A":   # 맑은 낮 하늘
        sky = [("0","#1F6FEB"),("0.55","#4FA3F7"),("1","#A9DEFF")]; glow="#FFFFFF"; gop=0.35
        pill_bg, pill_fg, lines = "#0B2A5B", "#FFFFFF", "#9CCBF5"
    elif v=="B": # 깊은 코발트, 고급
        sky = [("0","#0A2A66"),("0.6","#1E5BC6"),("1","#5FB4F5")]; glow="#BFE6FF"; gop=0.30
        pill_bg, pill_fg, lines = "#F3E7C9", "#0A2A66", "#8DB8EC"
    else:        # 파스텔 스카이블루
        sky = [("0","#3D8BFF"),("1","#86CFFF")]; glow="#FFFFFF"; gop=0.45
        pill_bg, pill_fg, lines = "#FFFFFF", "#1F6FEB", "#A8D3F7"
    st = "".join(f'<stop offset="{o}" stop-color="{c}"/>' for o,c in sky)
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
<defs>
 <linearGradient id="sky" x1="0" y1="0" x2="0.35" y2="1">{st}</linearGradient>
 <radialGradient id="glow" cx="0.78" cy="0.18" r="0.55"><stop offset="0" stop-color="{glow}" stop-opacity="{gop}"/><stop offset="1" stop-color="{glow}" stop-opacity="0"/></radialGradient>
 <linearGradient id="cl" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#E6F3FF"/></linearGradient>
 <filter id="sh" x="-30%" y="-30%" width="160%" height="170%"><feGaussianBlur stdDeviation="22"/></filter>
 <filter id="ps" x="-20%" y="-40%" width="140%" height="200%"><feDropShadow dx="0" dy="8" stdDeviation="12" flood-color="#06204A" flood-opacity="0.28"/></filter>
</defs>
<rect width="1024" height="1024" fill="url(#sky)"/>
<rect width="1024" height="1024" fill="url(#glow)"/>
{cloud(230,215,0.36,"#FFFFFF",'opacity="0.22"')}
{cloud(500,505,1.22,"#06204A",'opacity="0.24" filter="url(#sh)"').replace('translate(500,505)','translate(500,540)')}
{cloud(500,505,1.22,"url(#cl)")}
<g transform="translate(500,505) scale(1.22)" fill="{lines}">
 <rect x="-190" y="0" width="330" height="28" rx="14"/>
 <rect x="-190" y="54" width="240" height="28" rx="14"/>
</g>
<g filter="url(#ps)">
 <rect x="540" y="770" width="390" height="170" rx="85" fill="{pill_bg}"/>
 <text x="735" y="890" text-anchor="middle" font-family="Poppins" font-weight="700" font-size="112" letter-spacing="8" fill="{pill_fg}">PRO</text>
</g>
</svg>'''
for v in "ABC":
    open(f"icon_{v}.svg","w").write(icon(v))
