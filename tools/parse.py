import re, json, collections
src=open('src/Profession.lua').read()
# CLASSIC table only (until BCC block)
start=src.index('PROFESSION_DATA.CLASSIC = {'); end=src.index('if AtlasLoot:GameVersion_GE(AtlasLoot.BC_VERSION_NUM)', start)
body=src[start:end]
fstart=body.index('-- Forever Classic')
row=re.compile(r'\[(\d+)\]\s*=\s*\{\s*(nil|\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*\{([^}]*)\}\s*,\s*\{([^}]*)\}\s*(?:,\s*(\d+))?\s*\}')
recs={}
for part,forever in ((body[:fstart],False),(body[fstart:],True)):
    for m in row.finditer(part):
        sp,item,prof,lo,yel,grey,rg,rc,nc=m.groups()
        r=dict(spell=int(sp),item=None if item=='nil' else int(item),prof=int(prof),learn=int(lo),yellow=int(yel),grey=int(grey),
               mats=[int(x) for x in rg.split(',') if x.strip()],counts=[int(x) for x in rc.split(',') if x.strip()],n=int(nc or 1),forever=forever)
        if forever and r['spell'] in recs: r['override']=True
        recs[r['spell']]=r
json.dump(recs,open('recipes.json','w'))
P={1:'First Aid',2:'Blacksmithing',3:'Leatherworking',4:'Alchemy',6:'Cooking',7:'Mining',8:'Tailoring',9:'Engineering',10:'Enchanting',13:'Poisons'}
c=collections.Counter(); nocol=collections.Counter(); fv=collections.Counter(); ov=collections.Counter()
for r in recs.values():
    c[r['prof']]+=1
    if r['yellow']==0: nocol[r['prof']]+=1
    if r['forever']: fv[r['prof']]+=1
    if r.get('override'): ov[r['prof']]+=1
for p in sorted(c): print(f"{P.get(p,p):15s} total {c[p]:4d}  forever-section {fv[p]:4d}  (replacing classic {ov[p]:3d})  no colors {nocol[p]:4d}")
print(len(recs))
