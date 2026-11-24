# Fabrique docs/relecture_traductions.xlsx : toutes les phrases de Nguli
# en français, anglais, swahili et lingala, avec des colonnes pour corriger.
#   python3 docs/outils/fichier_relecture.py
import json, re
from openpyxl import Workbook
from openpyxl.styles import Alignment, Font, PatternFill, Border, Side
from openpyxl.worksheet.datavalidation import DataValidation

arb = {l: json.load(open(f'lib/l10n/app_{l}.arb', encoding='utf-8')) for l in ['fr', 'en', 'sw', 'ln']}

ECRANS = [
    ('pay', 'Caisse — paiement'), ('caisse', 'Caisse'), ('cart', 'Caisse — panier'), ('lot', 'Caisse — arrivages'),
    ('add', 'Caisse — ajout au panier'), ('scan', 'Scanner'), ('liv', 'Livraisons'), ('ret', 'Retours'),
    ('hist', 'Historique des ventes'), ('clo', 'Clôture de caisse'), ('acc', 'Accueil / comptes clients'),
    ('debt', 'Dettes et crédits'), ('stock', 'Stock'), ('imp', 'Stock — import'), ('arr', 'Stock — arrivages'),
    ('trf', 'Stock — transferts'), ('pb', 'Stock — prix par boutique'), ('pl', 'Stock — import'),
    ('ia', 'Stock — import photo'), ('rep', 'Rapport'), ('rc', 'Rapport — recherche client'),
    ('cpt', 'Comptabilité'), ('ecr', 'Comptabilité — écriture'), ('team', 'Équipe'), ('perm', 'Équipe — autorisations'),
    ('log', 'Connexion'), ('reg', 'Inscription'), ('pwd', 'Mot de passe'), ('del', 'Supprimer le compte'),
    ('account', 'Compte'), ('shop', 'Boutiques'), ('rate', 'Taux de change'), ('bak', 'Sauvegarde'),
    ('jrn', 'Journal'), ('sum', 'Résumé WhatsApp'), ('age', 'Dettes — ancienneté'),
]

def ecran(cle):
    for p, nom in sorted(ECRANS, key=lambda x: -len(x[0])):
        if cle.startswith(p) and (len(cle) == len(p) or not cle[len(p)].islower()):
            return nom
    return 'Général'

wb = Workbook()
guide = wb.active
guide.title = 'Mode d’emploi'
lignes_guide = [
    'Relecture des traductions de Nguli',
    '',
    '1. Allez dans la feuille « Phrases ».',
    '2. Lisez la colonne de VOTRE langue (Kiswahili ou Lingala), en la comparant au français.',
    '3. Si la phrase est juste : ne touchez à rien.',
    '4. Si elle est fausse ou maladroite : écrivez la bonne phrase dans la colonne « Correction » de votre langue.',
    '5. Gardez EXACTEMENT les mots entre accolades, par exemple {nom}, {montant}, {n} : Nguli les remplace',
    '   par le nom du client, un prix, un nombre… Vous pouvez les déplacer dans la phrase, pas les traduire.',
    '6. Gardez les émojis (💵 📦 ✔ …) et les « \\n » (retour à la ligne).',
    '7. Une remarque ? Écrivez-la dans la colonne « Remarque ».',
    '8. Renvoyez le fichier : les corrections seront mises dans l’application.',
    '',
    'Conseil : écrivez comme on parle à la caisse à Goma, simple et poli.',
]
for i, t in enumerate(lignes_guide, 1):
    c = guide.cell(row=i, column=1, value=t)
    c.font = Font(bold=(i == 1), size=14 if i == 1 else 12)
guide.column_dimensions['A'].width = 110

ws = wb.create_sheet('Phrases')
entetes = ['Écran', 'Clé (ne pas modifier)', 'Français', 'English', 'Kiswahili', 'Correction kiswahili',
           'Lingala', 'Correction lingala', 'Remarque']
largeurs = [24, 26, 48, 40, 44, 44, 44, 44, 30]
bleu = PatternFill('solid', fgColor='1E3A8A')
jaune = PatternFill('solid', fgColor='FFF7D6')
gris = PatternFill('solid', fgColor='F1F5F9')
fin = Side(style='thin', color='CBD5E1')
for j, (h, w) in enumerate(zip(entetes, largeurs), 1):
    c = ws.cell(row=1, column=j, value=h)
    c.font = Font(bold=True, color='FFFFFF')
    c.fill = bleu
    c.alignment = Alignment(wrap_text=True, vertical='center')
    ws.column_dimensions[c.column_letter].width = w
ws.row_dimensions[1].height = 30

cles = [k for k in arb['fr'] if not k.startswith('@')]
cles.sort(key=lambda k: (ecran(k), k))
for i, k in enumerate(cles, 2):
    valeurs = [ecran(k), k, arb['fr'].get(k, ''), arb['en'].get(k, ''), arb['sw'].get(k, ''), '',
               arb['ln'].get(k, ''), '', '']
    for j, v in enumerate(valeurs, 1):
        c = ws.cell(row=i, column=j, value=v)
        c.alignment = Alignment(wrap_text=True, vertical='top')
        c.border = Border(top=fin, bottom=fin, left=fin, right=fin)
        if j in (6, 8):
            c.fill = jaune
        elif j in (1, 2):
            c.fill = gris
            c.font = Font(color='64748B', size=9)
ws.freeze_panes = 'C2'
ws.auto_filter.ref = f'A1:I{len(cles) + 1}'
wb.save('docs/relecture_traductions.xlsx')
print(len(cles), 'phrases')
