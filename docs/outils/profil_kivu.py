import math, random
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

random.seed(7); np.random.seed(7)
S = 1080
F = '/usr/share/fonts/truetype/dejavu/'
ROUGE = (206, 16, 38); JAUNE = (247, 212, 23); BLEU = (0, 127, 255)
HORIZON = 560  # niveau du lac

def lerp(a, b, t): return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))

# ---------- Ciel : matin doré sur le Kivu ----------
y = np.linspace(0, 1, HORIZON)[:, None]
haut = np.array([30, 110, 200]); milieu = np.array([120, 185, 235]); bas = np.array([255, 205, 140])
t = y
ciel = np.where(t < 0.6, haut + (milieu - haut) * (t / 0.6), milieu + (bas - milieu) * ((t - 0.6) / 0.4))
ciel = np.repeat(ciel[:, None, :], S, axis=1)[:, :, 0, :] if ciel.ndim == 3 else np.repeat(ciel[:, None, :], S, axis=1)
arr = np.zeros((S, S, 3), dtype=float)
arr[:HORIZON] = ciel.reshape(HORIZON, S, 3) if ciel.size == HORIZON * S * 3 else np.broadcast_to(ciel.reshape(HORIZON, 1, 3), (HORIZON, S, 3))
# Soleil levant (lumière chaude)
sx, sy = 340, 385
yy, xx = np.mgrid[0:S, 0:S]
dist = np.hypot(xx - sx, yy - sy)
lueur = np.clip(1 - dist / 520, 0, 1) ** 2
arr[:HORIZON] += (lueur[:HORIZON, :, None] * np.array([120, 80, 20]))
img = Image.fromarray(np.clip(arr, 0, 255).astype('uint8'))

def couche():
    return Image.new('RGBA', (S, S), (0, 0, 0, 0))

def coller(c, flou=0):
    global img
    if flou: c = c.filter(ImageFilter.GaussianBlur(flou))
    img = Image.alpha_composite(img.convert('RGBA'), c).convert('RGB')

# Soleil
c = couche(); d = ImageDraw.Draw(c)
d.ellipse([sx - 48, sy - 48, sx + 48, sy + 48], fill=(255, 240, 190, 255))
coller(c, 3)

# Nuages doux
c = couche(); d = ImageDraw.Draw(c)
for cx_, cy_, n in [(170, 250, 7), (820, 190, 8), (560, 300, 5)]:
    for _ in range(n):
        rx = random.randint(50, 110); ry = random.randint(22, 40)
        x0 = cx_ + random.randint(-110, 110); y0 = cy_ + random.randint(-18, 18)
        d.ellipse([x0 - rx, y0 - ry, x0 + rx, y0 + ry], fill=(255, 250, 240, 150))
coller(c, 14)

# ---------- Volcans : Nyiragongo et sa chaîne ----------
def profil_volcan(cx_, base_y, larg, haut_, cratere):
    pts = []
    for i in range(-60, 61):
        u = i / 60
        x = cx_ + u * larg
        h = haut_ * (1 - abs(u)) ** 1.6
        if abs(u) < cratere: h = haut_ * (1 - cratere) ** 1.6 - 4
        pts.append((x, base_y - h + random.uniform(-1.5, 1.5)))
    return [(cx_ - larg, base_y)] + pts + [(cx_ + larg, base_y)]

c = couche(); d = ImageDraw.Draw(c)
d.polygon(profil_volcan(180, HORIZON, 330, 150, 0.05), fill=(120, 150, 185, 255))   # lointain
d.polygon(profil_volcan(1000, HORIZON, 300, 170, 0.06), fill=(115, 140, 175, 255))
coller(c, 2)
c = couche(); d = ImageDraw.Draw(c)
nx, nh = 720, 300
d.polygon(profil_volcan(nx, HORIZON, 420, nh, 0.09), fill=(70, 85, 105, 255))
coller(c, 1)
# lumière sur le flanc gauche
c = couche(); d = ImageDraw.Draw(c)
d.polygon([(nx - 420, HORIZON), (nx - 38, HORIZON - nh + 30), (nx - 120, HORIZON)], fill=(160, 120, 100, 70))
coller(c, 18)
# Lueur du cratère et panache de fumée
crx, cry = nx, HORIZON - int(nh * (1 - 0.09) ** 1.6)
c = couche(); d = ImageDraw.Draw(c)
d.ellipse([crx - 45, cry - 14, crx + 45, cry + 10], fill=(255, 110, 40, 200))
coller(c, 10)
c = couche(); d = ImageDraw.Draw(c)
for k in range(14):
    r = 22 + k * 7
    x0 = crx + k * 16 + random.randint(-6, 6); y0 = cry - 25 - k * 17
    d.ellipse([x0 - r, y0 - r * 0.7, x0 + r, y0 + r * 0.7], fill=(235, 225, 220, max(40, 150 - k * 8)))
coller(c, 12)

# ---------- Lac Kivu ----------
lac = np.zeros((90, S, 3), dtype=float)
for i in range(90):
    tt = i / 89
    lac[i] = lerp((150, 175, 190), (40, 95, 140), tt)
img_arr = np.array(img).astype(float)
img_arr[HORIZON:HORIZON + 90] = lac
img = Image.fromarray(img_arr.astype('uint8'))
c = couche(); d = ImageDraw.Draw(c)
for _ in range(90):  # reflets
    yy_ = HORIZON + random.randint(3, 85); x0 = random.randint(0, S)
    w = random.randint(15, 70)
    d.line([(x0, yy_), (x0 + w, yy_)], fill=(255, 245, 220, random.randint(60, 140)), width=2)
for k in range(12):  # reflet du soleil
    yy_ = HORIZON + 6 + k * 7; w = 60 - k * 4
    d.line([(sx - w, yy_), (sx + w, yy_)], fill=(255, 220, 150, 170), width=3)
coller(c, 1)
# petite pirogue
c = couche(); d = ImageDraw.Draw(c)
d.polygon([(470, 600), (540, 600), (530, 608), (480, 608)], fill=(40, 30, 25, 255))
d.line([(505, 600), (512, 578)], fill=(40, 30, 25, 255), width=3)
coller(c)

# ---------- Collines verdoyantes du Kivu ----------
def colline(base, amp, freqs, phase, couleur, texture=None, flou=0):
    c = couche(); d = ImageDraw.Draw(c)
    pts = [(0, S)]
    xs = range(0, S + 6, 6)
    prof = []
    for x in xs:
        h = base - sum(a * math.sin(x * f + p) for a, f, p in zip(amp, freqs, phase))
        prof.append((x, h)); pts.append((x, h))
    pts.append((S, S))
    d.polygon(pts, fill=couleur + (255,))
    if texture:  # arbres / buissons
        for _ in range(texture):
            x = random.randint(0, S - 1)
            top = prof[min(x // 6, len(prof) - 1)][1]
            yb = top + random.randint(4, 110)
            r = random.randint(6, 16)
            col = lerp(couleur, (0, 0, 0), random.uniform(0.1, 0.35)) if random.random() < 0.6 else lerp(couleur, (255, 255, 160), random.uniform(0.1, 0.25))
            d.ellipse([x - r, yb - r, x + r, yb + r], fill=col + (255,))
    coller(c, flou)
    return prof

colline(625, [18, 10], [0.006, 0.017], [0.4, 1.3], (95, 150, 95), texture=120, flou=1)
colline(675, [25, 12], [0.005, 0.021], [2.1, 0.2], (60, 130, 65), texture=180)
# champs en terrasses (cultures du Kivu)
c = couche(); d = ImageDraw.Draw(c)
for k in range(7):
    yk = 690 + k * 11
    d.arc([620, yk - 60, 1120, yk + 60], 190, 330, fill=(120, 165, 70, 160), width=3)
coller(c, 1)
colline(735, [30, 14], [0.004, 0.019], [1.0, 2.6], (35, 105, 50), texture=200)

# ---------- Premier plan : bananiers et herbes ----------
def feuille_bananier(d, x0, y0, angle, L, W, courbe, col):
    gauche, droite, axe = [], [], []
    for i in range(31):
        tt = i / 30
        a = math.radians(angle) + courbe * tt * tt
        x = x0 + L * tt * math.cos(a); y = y0 - L * tt * math.sin(a)
        axe.append((x, y))
        l = W * math.sin(math.pi * min(1, tt * 1.15)) * (1 - 0.25 * tt)
        nx_, ny_ = -math.sin(a), -math.cos(a)
        # déchirures typiques de la feuille de bananier
        dech = 0.55 if (i % 5 == 0 and tt > 0.2) else 1
        gauche.append((x + nx_ * l * dech, y + ny_ * l * dech))
        droite.append((x - nx_ * l, y - ny_ * l))
    d.polygon(gauche + droite[::-1], fill=col)
    d.line(axe, fill=(20, 70, 30, 255), width=3)

def bananier(c, x, sol, haut_, echelle=1.0, regime=False):
    d = ImageDraw.Draw(c)
    top = sol - haut_
    d.polygon([(x - 14 * echelle, sol), (x - 8 * echelle, top), (x + 8 * echelle, top), (x + 14 * echelle, sol)], fill=(85, 105, 45, 255))
    d.line([(x - 4, sol), (x - 2, top)], fill=(110, 130, 60, 255), width=3)
    angles = [20, 55, 85, 115, 150, 175, 5]
    for j, a in enumerate(angles):
        col = [(40, 140, 55), (60, 160, 60), (30, 115, 45), (80, 170, 70)][j % 4] + (255,)
        cb = -0.9 if a < 90 else 0.9
        feuille_bananier(d, x, top, a, 170 * echelle, 34 * echelle, cb * 0.8, col)
    if regime:
        for k in range(5):
            d.ellipse([x + 6, top + 18 + k * 13, x + 34, top + 34 + k * 13], fill=(95, 150, 40, 255))
        d.polygon([(x + 18, top + 90), (x + 30, top + 120), (x + 8, top + 118)], fill=(120, 30, 60, 255))

c = couche()
bananier(c, 95, 905, 230, 1.15, regime=True)
bananier(c, 1000, 900, 240, 1.2, regime=True)
bananier(c, 215, 860, 140, 0.75)
bananier(c, 885, 855, 150, 0.8)
coller(c)

# sol : sentier de terre rouge du Kivu
c = couche(); d = ImageDraw.Draw(c)
d.polygon([(470, 760), (610, 760), (760, S), (330, S)], fill=(165, 85, 50, 255))
d.polygon([(500, 760), (580, 760), (650, S), (420, S)], fill=(185, 100, 60, 120))
coller(c, 2)

# hautes herbes
c = couche(); d = ImageDraw.Draw(c)
for _ in range(650):
    x = random.randint(0, S); yb = random.randint(790, S)
    if 360 + (yb - 760) * -0.3 < x < 720 + (yb - 760) * 0.3 and random.random() < 0.85: continue
    h = random.randint(25, 70); pen = random.uniform(-0.5, 0.5)
    col = random.choice([(40, 120, 45), (70, 150, 55), (110, 170, 60), (30, 95, 40), (150, 180, 70)])
    d.polygon([(x - 3, yb), (x + pen * h, yb - h), (x + 3, yb)], fill=col + (255,))
# fleurs
for _ in range(40):
    x = random.randint(0, S); yb = random.randint(800, 900)
    if 330 < x < 760: continue
    col = random.choice([(250, 210, 30), (240, 70, 60), (255, 255, 255)])
    d.ellipse([x - 4, yb - 4, x + 4, yb + 4], fill=col + (255,))
coller(c)

# oiseaux
d = ImageDraw.Draw(img)
for bx, by, s in [(420, 200, 12), (455, 220, 9), (390, 230, 8), (880, 330, 10)]:
    d.line([(bx - s, by - s * 0.4), (bx, by), (bx + s, by - s * 0.4)], fill=(40, 40, 50), width=3, joint='curve')

# ---------- Commerçante Nguli ----------
fg = Image.open('/home/user/stockly_saas/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png').convert('RGBA')
fg = fg.crop(fg.getbbox()); h = 300; w = int(fg.width * h / fg.height); fg = fg.resize((w, h), Image.LANCZOS)
fx, fyb = (S - w) // 2, 752
ombre = couche(); ImageDraw.Draw(ombre).ellipse([S // 2 - 90, fyb - 14, S // 2 + 90, fyb + 14], fill=(0, 0, 0, 110))
coller(ombre, 6)
img = img.convert('RGBA'); img.alpha_composite(fg, (fx, fyb - h + 8)); img = img.convert('RGB')

# ---------- Bandeau RDC et textes ----------
# voile sombre pour la lisibilité
c = couche(); d = ImageDraw.Draw(c)
for i in range(200):
    d.line([(0, S - 200 + i), (S, S - 200 + i)], fill=(10, 30, 15, int(170 * i / 200)))
coller(c)
c = couche(); d = ImageDraw.Draw(c)
d.polygon([(0, 905), (S, 865), (S, 885), (0, 925)], fill=JAUNE + (255,))
d.polygon([(0, 925), (S, 885), (S, 900), (0, 940)], fill=ROUGE + (255,))
coller(c)

d = ImageDraw.Draw(img)
def texte(xy, s, taille, fill, ombre=True):
    f = ImageFont.truetype(F + 'DejaVuSans-Bold.ttf', taille)
    if ombre:
        sh = couche(); ImageDraw.Draw(sh).text((xy[0] + 3, xy[1] + 4), s, font=f, fill=(0, 0, 0, 200), anchor='mm')
        coller(sh, 4)
    ImageDraw.Draw(img).text(xy, s, font=f, fill=fill, anchor='mm')

# étoile RDC dans le ciel
c = couche(); d = ImageDraw.Draw(c)
pts = [(160 + (60 if k % 2 == 0 else 24) * math.cos(-math.pi / 2 + k * math.pi / 5), 330 + (60 if k % 2 == 0 else 24) * math.sin(-math.pi / 2 + k * math.pi / 5)) for k in range(10)]
d.polygon(pts, fill=JAUNE + (255,))
coller(c)

texte((S // 2, 135), "Le grenier de ton commerce", 42, 'white')
texte((S // 2, 832), "Nguli", 116, 'white')
texte((S // 2, 962), "Vente • Caisse • Stock • Crédit", 34, JAUNE)

img.save('/home/user/stockly_saas/docs/nguli_profil_whatsapp_kivu.png')
m = Image.new('L', (S, S), 0); ImageDraw.Draw(m).ellipse([0, 0, S, S], fill=255)
ap = Image.new('RGB', (S, S), (255, 255, 255)); ap.paste(img, (0, 0), m)
ap.resize((540, 540), Image.LANCZOS).save('/tmp/claude-0/-home-user-stockly-saas/d670bdaa-b0b1-5bf1-aea1-04d9ccd0ff58/scratchpad/apercu_kivu.png')
print('ok')
