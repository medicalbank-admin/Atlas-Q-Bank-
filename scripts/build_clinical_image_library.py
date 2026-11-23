import ast,csv,json,re,time,urllib.parse,urllib.request
from pathlib import Path
from io import BytesIO
ROOT=Path("."); OUT=ROOT/"assets/images/clinical"; OUT.mkdir(parents=True,exist_ok=True)
UA="AtlasAcademy clinical education image curator"
def get(url,binary=False):
 r=urllib.request.urlopen(urllib.request.Request(url,headers={"User-Agent":UA}),timeout=45)
 b=r.read(); return b if binary else b.decode("utf-8")
# Each ECG case is matched only to a corresponding PTB-XL diagnostic code.
ECG={"01":["NORM"],"02":["SBRAD"],"03":["SBRAD"],"04":["STACH"],"06":["AFIB"],"07":["AFIB"],"08":["AFIB"],"09":["AFLT"],"10":["AFLT"],"11":["SVT"],"12":["SVT"],"13":["SVT"],"14":["SVT"],"15":["PAC"],"16":["PVC"],"17":["PVC"],"18":["VT"],"19":["VT"],"20":["VT"],"21":["VF"],"23":["1AVB"],"24":["2AVB"],"25":["2AVB"],"26":["3AVB"],"27":["RBBB"],"28":["LBBB"],"32":["AMI","ASMI"],"33":["IMI"],"34":["LMI"],"35":["PMI"],"36":["IMI"],"44":["LNGQT"],"50":["RVH"],"51":["LVH"],"58":["AMI","ASMI"],"60":["NST_"],"62":["PACE"],"63":["PACE"],"64":["PACE"],"70":["IVCD"],"72":["AMI","ASMI"],"77":["AFIB"],"78":["VT"],"79":["PMI"],"80":["AMI","ASMI"]}
def ecg():
 base="https://physionet.org/files/ptb-xl/1.0.3/"
 rows=list(csv.DictReader(get(base+"ptbxl_database.csv").splitlines())); used=set(); found=[]
 import wfdb,matplotlib
 matplotlib.use("Agg")
 import matplotlib.pyplot as plt
 for cid,codes in ECG.items():
  match=None
  for row in rows:
   try: labels=ast.literal_eval(row["scp_codes"])
   except: continue
   code=next((x for x in codes if x in labels),None)
   if code and row["ecg_id"] not in used: match=(row,code); used.add(row["ecg_id"]); break
  if not match: continue
  row,code=match; rel=row["filename_lr"]
  for ext in (".hea",".dat"):
   p=ROOT/(rel+ext); p.parent.mkdir(parents=True,exist_ok=True)
   if not p.exists(): p.write_bytes(get(base+rel+ext,True))
  rec=wfdb.rdrecord(str(ROOT/rel)); fig,axs=plt.subplots(12,1,figsize=(13,10),sharex=True)
  for i,ax in enumerate(axs):
   ax.plot(rec.p_signal[:,i],lw=.65,color="#172d3c"); ax.set_ylabel(rec.sig_name[i],rotation=0,labelpad=22,fontsize=7)
   ax.set_facecolor("#fffafa"); ax.grid(True,lw=.3,color="#e7b9b9"); ax.tick_params(left=False,labelleft=False,bottom=False,labelbottom=False)
   for sp in ax.spines.values(): sp.set_visible(False)
  fig.suptitle("PTB-XL real clinical ECG • record "+str(row["ecg_id"])); fig.tight_layout()
  dest=OUT/"ecg"/(cid+".png"); dest.parent.mkdir(parents=True,exist_ok=True); fig.savefig(dest,dpi=130); plt.close(fig)
  found.append({"caseId":cid,"file":str(dest),"recordId":row["ecg_id"],"scpCode":code,"dataset":"PTB-XL v1.0.3","source":"https://physionet.org/content/ptb-xl/1.0.3/","license":"CC BY 4.0","attribution":"Wagner et al., PTB-XL (2020), PhysioNet, CC BY 4.0. Record "+str(row["ecg_id"])})
 return found
def radiology():
 src=Path("lib/features/advanced_learning/screens/atlas_radiology_learning_screen.dart").read_text()
 cases=re.findall(r"_Case\('([^']+)','([^']+)','([^']+)'",src); found=[]; seen=set()
 approved=("cc by","cc-by","cc0","public domain","cc by-sa","cc-by-sa","gnu free documentation")
 from PIL import Image
 for cid,mod,title in cases:
  q=urllib.parse.urlencode({"action":"query","format":"json","generator":"search","gsrsearch":title+" "+mod+" radiology","gsrnamespace":6,"gsrlimit":10,"prop":"imageinfo","iiprop":"url|extmetadata","iiurlwidth":1600})
  try: pages=json.loads(get("https://commons.wikimedia.org/w/api.php?"+q)).get("query",{}).get("pages",{}).values()
  except Exception as e: print("Commons API",cid,e); continue
  words={w for w in re.findall(r"[a-z0-9]+",title.lower()) if len(w)>3}; choice=None
  for page in pages:
   info=(page.get("imageinfo") or [{}])[0]; meta=info.get("extmetadata") or {}
   lic=re.sub("<[^>]+>"," ",meta.get("LicenseShortName",{}).get("value","")).lower()
   desc=re.sub("<[^>]+>"," ",meta.get("ImageDescription",{}).get("value","")).lower()
   text=(page.get("title","")+" "+desc).lower()
   hits=sum(w in text for w in words)
   if hits>=min(2,len(words)) and any(x in lic for x in approved):
    url=info.get("thumburl") or info.get("url")
    if url and url not in seen: choice=(page,info,meta,lic,url,hits); break
  if not choice: continue
  page,info,meta,lic,url,hits=choice
  try:
   im=Image.open(BytesIO(get(url,True))).convert("RGB")
   if im.width<350 or im.height<250: continue
   im.thumbnail((1600,1600)); dest=OUT/"radiology"/(cid+".jpg"); dest.parent.mkdir(parents=True,exist_ok=True); im.save(dest,"JPEG",quality=88,optimize=True)
  except Exception as e: print("Rejected",cid,e); continue
  seen.add(url); artist=re.sub("<[^>]+>"," ",meta.get("Artist",{}).get("value","")).strip()
  found.append({"caseId":cid,"modality":mod,"diagnosis":title,"file":str(dest),"commonsTitle":page.get("title"),"sourcePage":info.get("descriptionurl"),"author":artist,"license":lic,"licenseUrl":meta.get("LicenseUrl",{}).get("value",""),"attribution":artist+" — "+lic+" — "+str(info.get("descriptionurl"))})
  time.sleep(.15)
 return found
e=ecg(); r=radiology()
manifest={"generatedUtc":time.strftime("%Y-%m-%dT%H:%M:%SZ",time.gmtime()),"ecgCount":len(e),"radiologyCount":len(r),"ecg":e,"radiology":r,"policy":"Only diagnosis-matched real clinical images with declared reuse licenses are included. Unmatched cases remain without images."}
(OUT/"image_manifest.json").write_text(json.dumps(manifest,indent=2,ensure_ascii=False))
print("ECG verified:",len(e),"/80; radiology verified:",len(r),"/80")
