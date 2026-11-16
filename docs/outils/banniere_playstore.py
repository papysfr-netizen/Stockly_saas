# Bannière du Play Store (1024 × 500) : paysage du Kivu + commerçante + textes
#   ICONE=1 SORTIE=fond.png python3 docs/outils/profil_kivu.py   (le paysage seul)
#   python3 docs/outils/banniere_playstore.py fond.png
import sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

F = '/usr/share/fonts/truetype/dejavu/'
JAUNE = (247, 212, 23); ROUGE = (206, 16, 38)
W, H = 1024, 500

fond = Image.open(sys.argv[1]).convert('RGBA')          # 1080 × 1080
fond = fond.resize((1120, 1120), Image.LANCZOS).crop((48, 250, 48 + W, 250 + H))
img = fond.copy()

# voile sombre à droite pour lire les textes
voile = Image.new('RGBA', (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(voile)
for x in range(W):
    a = int(max(0, (x - 330) / (W - 330)) ** 0.9 * 185)
    d.line([(x, 0), (x, H)], fill=(8, 25, 15, a))
img.alpha_composite(voile)

# commerçante à gauche
fg = Image.open('docs/outils/commercante.png').convert('RGBA'); fg = fg.crop(fg.getbbox())
h = 350; w = int(fg.width * h / fg.height); fg = fg.resize((w, h), Image.LANCZOS)
ombre = Image.new('RGBA', (W, H), (0, 0, 0, 0))
ImageDraw.Draw(ombre).ellipse([215 - 85, H - 30, 215 + 85, H - 4], fill=(0, 0, 0, 110))
img.alpha_composite(ombre.filter(ImageFilter.GaussianBlur(6)))
img.alpha_composite(fg, (215 - w // 2, H - h - 12))

def texte(xy, s, taille, fill, anchor='lm'):
    f = ImageFont.truetype(F + 'DejaVuSans-Bold.ttf', taille)
    sh = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(sh).text((xy[0] + 3, xy[1] + 4), s, font=f, fill=(0, 0, 0, 200), anchor=anchor)
    img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(4)))
    ImageDraw.Draw(img).text(xy, s, font=f, fill=fill, anchor=anchor)

x0 = 455
texte((x0, 150), 'Nguli', 112, 'white')
texte((x0 + 4, 238), 'Le grenier de ton commerce', 30, 'white')
d = ImageDraw.Draw(img)
d.rectangle([x0 + 4, 285, x0 + 500, 293], fill=JAUNE)
d.rectangle([x0 + 4, 293, x0 + 500, 299], fill=ROUGE)
texte((x0 + 4, 340), 'Vente • Caisse • Stock • Crédit', 27, JAUNE)
texte((x0 + 4, 392), 'Fait à Goma, pour les commerçants', 22, (230, 240, 230))
texte((x0 + 4, 424), 'du Congo et des Grands Lacs', 22, (230, 240, 230))
img.convert('RGB').save('docs/nguli_banniere_playstore_1024x500.png')
print('ok')
