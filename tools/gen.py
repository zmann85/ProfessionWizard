import re, json, collections
J='/home/claude/bparish628/wow-profession-journal/Data/Recipes.lua'
atlas=json.load(open('recipes.json'))
# Thorium Greatsword: not taught by trainers, it needs Plans: Thorium Greatsword (12816), seen in game 14 Nov 2026
OVERRIDES={16960:(12816,False), 2334:(None,True)}  # 2334 Elixir of Minor Fortitude: trainer; 2554 is a deprecated item
# New Forever recipes taught by a recipe item that the client data calls trainer recipes (from wowcraft.io's
# Forever data, 14 Nov 2026): spell -> recipe item
OVERRIDES.update({ 1251744:(250991,False), 1252237:(251340,False), 1252239:(251342,False), 1252240:(251343,False), 1252241:(251344,False), 1252242:(251345,False), 1252243:(251346,False), 1252244:(251347,False), 1252245:(251348,False), 1252246:(251349,False), 1252247:(251350,False), 1252248:(251351,False), 1252249:(251352,False), 1252250:(251353,False), 1252251:(251354,False), 1252292:(251395,False), 1252323:(251426,False), 1249107:(249519,False), 1249112:(249520,False), 1249114:(249521,False), 1293088:(274049,False), 1255088:(252819,False), 1255089:(252818,False), 1255090:(252817,False), 1255091:(252816,False), 1255092:(252815,False), 1255093:(252814,False), 1255110:(252797,False), 1255111:(252796,False), 1255112:(252795,False), 1255113:(252794,False), 1255114:(252793,False), 1255115:(252792,False), 1255131:(252776,False), 1255132:(252775,False), 1255133:(252774,False), 1255134:(252773,False), 1255135:(252772,False), 1255136:(252771,False) })
# A recipe the client data calls "trainer" that has a plans/pattern/formula/recipe item in AtlasLoot's
# Data/Recipe.lua (Classic block) is taught by that item: 45 such recipes were planned as trainer recipes
# (Ornate Mithril, Bleakwood Hew, Rune Edge ...). Put AtlasLoot's Recipe.lua in src/ to apply this rule.
import os
TEACH={}
if os.path.exists('src/Recipe.lua'):
    _al=open('src/Recipe.lua',encoding='utf-8',errors='replace').read()
    _al=_al[_al.find('RECIPE_DATA.CLASSIC'):_al.find('RECIPE_DATA.BCC')]
    for _it,_pr,_rk,_sp,_nm in re.findall(r'\[(\d+)\]\s*=\s*\{\s*(\d+),\s*(\d+),\s*(\d+)\s*\},?\s*--\s*([^\n]*)', _al):
        if re.match(r'(Plans|Pattern|Formula|Recipe|Schematic|Manual)\b', _nm.strip()):
            TEACH.setdefault(int(_sp), int(_it))
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
    # corrections the client data gets wrong: (plans item, from trainer)
    if sp in OVERRIDES: ri, trainer = OVERRIDES[sp]; ri = ri or 0
    elif trainer and not ri and sp in TEACH: ri, trainer = TEACH[sp], False
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
