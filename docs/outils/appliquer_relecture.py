# Reporte les corrections du fichier de relecture dans l'application.
#   python3 docs/outils/appliquer_relecture.py chemin/vers/relecture_corrigee.xlsx
# Puis : flutter gen-l10n
import json, re, sys
from openpyxl import load_workbook

ws = load_workbook(sys.argv[1])['Phrases']
entetes = [c.value for c in ws[1]]
col = {h: i for i, h in enumerate(entetes)}
corrections = {'sw': {}, 'ln': {}}
for ligne in ws.iter_rows(min_row=2, values_only=True):
    cle = ligne[col['Clé (ne pas modifier)']]
    for l, nom in [('sw', 'Correction kiswahili'), ('ln', 'Correction lingala')]:
        v = ligne[col[nom]]
        if cle and v and str(v).strip():
            corrections[l][cle] = str(v).strip()

fr = json.load(open('lib/l10n/app_fr.arb', encoding='utf-8'))
for l, corr in corrections.items():
    p = f'lib/l10n/app_{l}.arb'
    texte = open(p, encoding='utf-8').read()
    for cle, v in corr.items():
        attendus = set(re.findall(r'\{(\w+)\}', fr.get(cle, '')))
        trouves = set(re.findall(r'\{(\w+)\}', v))
        # Les phrases mises bout à bout (message WhatsApp) gardent leur espace final
        if fr.get(cle, '').endswith(' ') and not v.endswith(' '):
            v += ' '
        if attendus != trouves:
            print(f'⚠️ {l} {cle} : accolades différentes ({sorted(trouves)} au lieu de {sorted(attendus)}) — ignorée')
            continue
        nouveau, n = re.subn(r'(^\s*"%s":\s*)"(?:[^"\\]|\\.)*"' % re.escape(cle),
                             lambda m: m.group(1) + json.dumps(v, ensure_ascii=False), texte, count=1, flags=re.M)
        if n == 0:
            print(f'⚠️ {l} {cle} : clé introuvable — ignorée')
            continue
        texte = nouveau
    open(p, 'w', encoding='utf-8').write(texte)
    print(l, len(corr), 'correction(s) lue(s)')
