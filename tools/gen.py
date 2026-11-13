import re, json, collections
J='/home/claude/bparish628/wow-profession-journal/Data/Recipes.lua'
atlas=json.load(open('recipes.json'))
PROF={171:'Alchemy',164:'Blacksmithing',185:'Cooking',333:'Enchanting',202:'Engineering',129:'First Aid',165:'Leatherworking',186:'Mining',40:'Poisons',197:'Tailoring'}
num=lambda k,s:(lambda m:int(m.group(1)) if m else None)(re.search(r'\b'+k+r' = (\d+)',s))
recs=collections.defaultdict(list); est=collections.Counter(); shifted=0
for line in open(J):
    if 'spell =' not in line: continue
    body,_,name=line.partition('}, --'); name=name.strip()
    p=num('profession',line)
    if p not in PROF: continue
    sp=num('spell',body); y=num('yellow',body); g=num('grey',body); sk=num('skill',body)
    cr=num('creates',body); ri=num('recipeItem',body)
    mats=re.findall(r'item = (\d+), count = (\d+)',body)
    trainer='kind = "trainer"' in body
    a=atlas.get(str(sp))
    n=(a or {}).get('n',1) or 1
    learn=sk
    if learn is None and a:
        if a['yellow']>0 and y: learn=a['learn']-(a['yellow']-y); shifted+=1
        else: learn=a['learn']
    if learn is None:
        learn=max(1,(y or 1)-25); est[PROF[p]]+=1
    if y is None or y==0: y=learn
    if g is None or g==0: g=y+25
    learn=max(1,min(learn,y))
    recs[p].append((sp,learn,y,g,cr or 0,n,ri or 0,1 if trainer else 0,name,[(int(i),int(c)) for i,c in mats]))
out=['-- ProfessionWizard_Data (GNU GPL v2, see LICENSE.txt): recipe data for Profession Wizard.','local ns = ProfessionWizardAPI','if not ns then return end','-- Generated from WoW Forever client data (build 1.60.1.70245, via wow-profession-journal, MIT)',
     '-- plus AtlasLoot (GPL) learn levels and crafted amounts. Do not edit by hand: rerun gen.py.',
     '-- { spell, learn, yellow, grey, creates, amountMade, plansItem, fromTrainer, name, { item, count, item, count, ... } }',
     'ns.RECIPES = {']
for p in sorted(recs):
    out.append(f'  [{p}] = {{ -- {PROF[p]}')
    for r in sorted(recs[p],key=lambda r:(r[1],r[2],r[0])):
        mats=', '.join(f'{i}, {c}' for i,c in r[9])
        nm=r[8].replace('\\','\\\\').replace('"','\\"')
        out.append(f'    {{ {r[0]}, {r[1]}, {r[2]}, {r[3]}, {r[4]}, {r[5]}, {r[6]}, {r[7]}, "{nm}", {{ {mats} }} }},')
    out.append('  },')
out.append('}')
open('../ProfessionWizard_Data/Recipes.lua','w').write('\n'.join(out)+'\n')
for p in sorted(recs): print(f"{PROF[p]:15s} {len(recs[p]):4d} recipes, learn level estimated for {est[PROF[p]]}")
print('learn levels shifted from AtlasLoot:',shifted)
# spot checks
byspell={r[0]:r for p in recs for r in recs[p]}
for sp in (9993,10001,16639,16960,16656,9964,3115,16641):
    r=byspell.get(sp); print(sp, r[8] if r else None, r[1:5] if r else None)
