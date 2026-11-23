#!/usr/bin/env python3
"""Build 3D small-molecule assets for every Atlas clinical-pharmacology drug.

Coordinates are either PubChem 3D conformers or deterministic RDKit-generated
conformers from PubChem isomeric SMILES. They are molecular conformers, NOT
experimental protein-bound poses or docking/energy simulations.
"""
import json, math, os, struct, time, urllib.parse, urllib.request, urllib.error

ROOT = "assets/pharmacology/molecular"
CATALOG = os.path.join(ROOT, "drug_target_catalog.json")
ELEMENTS = {
 "C": ([0.66,0.70,0.75,1],0.18), "N": ([0.20,0.42,0.95,1],0.17),
 "O": ([0.92,0.22,0.20,1],0.16), "S": ([0.96,0.72,0.12,1],0.21),
 "P": ([1.00,0.48,0.12,1],0.21), "F": ([0.45,0.82,0.40,1],0.16),
 "CL": ([0.20,0.75,0.25,1],0.20), "BR": ([0.55,0.30,0.18,1],0.22),
 "I": ([0.48,0.22,0.62,1],0.24), "H": ([0.88,0.90,0.94,1],0.09),
 "B": ([0.95,0.70,0.45,1],0.17), "SI": ([0.70,0.62,0.50,1],0.20)
}
def get(url, attempts=7):
    req=urllib.request.Request(url,headers={"User-Agent":"AtlasAcademy-Pharmacology-Lab/1.0"})
    for attempt in range(attempts):
        try:
            with urllib.request.urlopen(req,timeout=90) as r: return r.read()
        except urllib.error.HTTPError as error:
            if error.code not in (429,500,502,503,504) or attempt == attempts-1:
                raise
            retry_after=error.headers.get("Retry-After")
            delay=float(retry_after) if retry_after else min(2 ** attempt, 24)
            print("PubChem/structure server returned HTTP %s; retrying in %ss"%(error.code,delay))
            time.sleep(delay)
        except urllib.error.URLError:
            if attempt == attempts-1: raise
            time.sleep(min(2 ** attempt,24))
    raise RuntimeError("Network retries exhausted")
def sphere():
    v=[(0,0,1),(0.894,0,0.447),(0.276,0.851,0.447),(-0.724,0.526,0.447),(-0.724,-0.526,0.447),(0.276,-0.851,0.447),
       (0.724,0.526,-0.447),(-0.276,0.851,-0.447),(-0.894,0,-0.447),(-0.276,-0.851,-0.447),(0.724,-0.526,-0.447),(0,0,-1)]
    f=[(0,1,2),(0,2,3),(0,3,4),(0,4,5),(0,5,1),(1,6,2),(2,6,7),(2,7,3),(3,7,8),(3,8,4),(4,8,9),(4,9,5),(5,9,10),(5,10,1),(1,10,6),(11,7,6),(11,8,7),(11,9,8),(11,10,9),(11,6,10)]
    return v,[x for tri in f for x in tri]
def cylinder():
    v=[]; faces=[]; n=10
    for y in (-0.5,0.5):
        for i in range(n):
            a=2*math.pi*i/n; v.append((math.cos(a),y,math.sin(a)))
    for i in range(n):
        j=(i+1)%n; faces.extend((i,j,n+j,i,n+j,n+i))
    faces.extend(tuple(reversed(range(n)))); faces.extend(range(n,2*n))
    return v,faces
def glb(path, atoms, bonds, title):
    if not atoms: raise RuntimeError("No molecular atoms: "+title)
    xyz=[a["xyz"] for a in atoms]
    center=[sum(p[i] for p in xyz)/len(xyz) for i in range(3)]
    extent=max(max(abs(p[i]-center[i]) for p in xyz) for i in range(3)) or 1
    scale=1.65/extent
    sv,si=sphere(); cv,ci=cylinder()
    binary=bytearray(); views=[]; accessors=[]
    def blob(data,target):
        while len(binary)%4: binary.append(0)
        off=len(binary); binary.extend(data)
        views.append({"buffer":0,"byteOffset":off,"byteLength":len(data),"target":target})
        return len(views)-1
    def geometry(vertices,indices):
        p=struct.pack("<"+"f"*(len(vertices)*3),*[z for v in vertices for z in v])
        pv=blob(p,34962); pa=len(accessors)
        accessors.append({"bufferView":pv,"componentType":5126,"count":len(vertices),"type":"VEC3",
          "min":[min(v[i] for v in vertices) for i in range(3)],"max":[max(v[i] for v in vertices) for i in range(3)]})
        ix=struct.pack("<"+"H"*len(indices),*indices); iv=blob(ix,34963); ia=len(accessors)
        accessors.append({"bufferView":iv,"componentType":5123,"count":len(indices),"type":"SCALAR"})
        return pa,ia
    sphere_pos,sphere_idx=geometry(sv,si); cyl_pos,cyl_idx=geometry(cv,ci)
    materials=[]; meshes=[]; nodes=[]; mesh_map={}
    for el,(color,radius) in ELEMENTS.items():
        mesh_map[el]=len(meshes)
        materials.append({"name":"Element "+el,"pbrMetallicRoughness":{"baseColorFactor":color,"metallicFactor":0.04,"roughnessFactor":0.34}})
        meshes.append({"name":"Atom "+el,"primitives":[{"attributes":{"POSITION":sphere_pos},"indices":sphere_idx,"material":len(materials)-1}]})
    bond_material=len(materials)
    materials.append({"name":"Covalent bonds","pbrMetallicRoughness":{"baseColorFactor":[0.48,0.56,0.64,1],"metallicFactor":0.05,"roughnessFactor":0.5}})
    bond_mesh=len(meshes); meshes.append({"name":"Covalent bond","primitives":[{"attributes":{"POSITION":cyl_pos},"indices":cyl_idx,"material":bond_material}]})
    for idx,a in enumerate(atoms):
        el=a["element"].upper()
        if el not in ELEMENTS: el="C"
        radius=ELEMENTS[el][1]
        nodes.append({"name":"ATOM_%03d_%s_%s"%(idx+1,el,a.get("name",""))[:60],"mesh":mesh_map[el],
          "translation":[(a["xyz"][i]-center[i])*scale for i in range(3)],"scale":[radius*scale*2.1]*3})
    for bi,(ia,ib,order) in enumerate(bonds):
        if ia>=len(atoms) or ib>=len(atoms): continue
        p=atoms[ia]["xyz"]; q=atoms[ib]["xyz"]
        d=[q[i]-p[i] for i in range(3)]; length=math.sqrt(sum(x*x for x in d))
        if length<1e-5: continue
        mid=[(p[i]+q[i])*0.5 for i in range(3)]
        # Quaternion rotating the cylinder's local +Y axis onto the bond vector.
        ux,uy,uz=d[0]/length,d[1]/length,d[2]/length
        qw=math.sqrt(max(0,1+uy))*0.5
        if qw>1e-7: qx=uz/(4*qw); qy=0.0; qz=-ux/(4*qw)
        else: qx=1.0; qy=0.0; qz=0.0
        nodes.append({"name":"BOND_%03d"%(bi+1),"mesh":bond_mesh,
          "translation":[(mid[i]-center[i])*scale for i in range(3)],
          "rotation":[qx,qy,qz,qw],"scale":[0.045*scale*2.1,length*scale,0.045*scale*2.1]})
    doc={"asset":{"version":"2.0","generator":"Atlas Academy PubChem/RDKit molecular conformer builder"},
      "scene":0,"scenes":[{"nodes":list(range(len(nodes)))}],"nodes":nodes,"meshes":meshes,"materials":materials,
      "buffers":[{"byteLength":len(binary)}],"bufferViews":views,"accessors":accessors}
    js=json.dumps(doc,separators=(",",":")).encode()
    while len(js)%4: js+=b" "
    while len(binary)%4: binary.append(0)
    total=12+8+len(js)+8+len(binary)
    with open(path,"wb") as f:
        f.write(struct.pack("<4sII",b"glTF",2,total)); f.write(struct.pack("<I4s",len(js),b"JSON")); f.write(js)
        f.write(struct.pack("<I4s",len(binary),b"BIN\x00")); f.write(binary)
def parse_sdf(sdf):
    lines=sdf.splitlines()
    if len(lines)<5: raise ValueError("Invalid SDF")
    counts=lines[3]
    na=int(counts[:3]); nb=int(counts[3:6])
    atoms=[]
    for line in lines[4:4+na]:
        atoms.append({"xyz":(float(line[0:10]),float(line[10:20]),float(line[20:30])),
                      "element":line[31:34].strip().upper(),"name":line[31:34].strip()})
    bonds=[]
    for line in lines[4+na:4+na+nb]:
        bonds.append((int(line[:3])-1,int(line[3:6])-1,int(line[6:9])))
    return atoms,bonds
def pubchem_conformer(item):
    name=item["pubchem_name"]
    cid=item.get("pubchem_cid")
    base=("https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/%s"%cid) if cid else ("https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/name/%s"%urllib.parse.quote(name,safe=""))
    # Prefer PubChem's deposited 3D conformer.
    try:
        sdf=get(base+"/SDF?record_type=3d").decode("utf-8","replace")
        atoms,bonds=parse_sdf(sdf)
        if atoms and any(abs(a["xyz"][2])>0.01 for a in atoms):
            return atoms,bonds,"PubChem 3D conformer"
    except Exception as e: print("PubChem 3D unavailable for %s: %s"%(name,e))
    # Fall back to an RDKit 3D conformer generated from the PubChem isomeric structure.
    from rdkit import Chem
    from rdkit.Chem import AllChem
    smiles=None
    for prop in ("IsomericSMILES","CanonicalSMILES","SMILES","ConnectivitySMILES"):
        try:
            raw=json.loads(get(base+"/property/"+prop+"/JSON"))
            record=raw["PropertyTable"]["Properties"][0]
            smiles=(record.get(prop) or record.get("SMILES") or
                    record.get("ConnectivitySMILES") or record.get("CanonicalSMILES") or
                    record.get("IsomericSMILES"))
            if smiles: break
        except Exception as error:
            print("PubChem %s descriptor unavailable for %s: %s"%(prop,name,error))
    if not smiles: raise RuntimeError("PubChem returned no usable isomeric/canonical SMILES for "+name)
    mol=Chem.MolFromSmiles(smiles)
    if mol is None: raise RuntimeError("Could not parse PubChem SMILES for "+name)
    large=mol.GetNumHeavyAtoms()>200
    if not large: mol=Chem.AddHs(mol)
    params=AllChem.ETKDGv3(); params.randomSeed=20261123; params.useRandomCoords=False
    params.maxIterations=80 if large else 500
    status=AllChem.EmbedMolecule(mol,params)
    if status!=0: raise RuntimeError("RDKit could not generate 3D conformer for "+name)
    if not large and AllChem.MMFFHasAllMoleculeParams(mol):
        AllChem.MMFFOptimizeMolecule(mol,maxIters=200)
    conf=mol.GetConformer()
    atoms=[]
    for i,a in enumerate(mol.GetAtoms()):
        p=conf.GetAtomPosition(i)
        atoms.append({"xyz":(p.x,p.y,p.z),"element":a.GetSymbol().upper(),"name":str(i+1)})
    bonds=[(b.GetBeginAtomIdx(),b.GetEndAtomIdx(),int(b.GetBondTypeAsDouble())) for b in mol.GetBonds()]
    method="RDKit ETKDGv3 computed conformer from PubChem isomeric SMILES"
    if large: method+=" (large flexible molecule; illustrative heavy-atom conformation)"
    return atoms,bonds,method
def main():
    os.makedirs(ROOT,exist_ok=True)
    with open(CATALOG) as f: catalog=json.load(f)
    manifest={}
    failures=[]
    for item in catalog:
        slug=item["slug"]; name=item["pubchem_name"]
        try:
            if item.get("experimental_complex_only"):
                manifest[slug]={**item,"asset":None,"structure_status":"experimental drug–target complex displayed in the clinical profile",
                    "coordinate_method":"Experimental PDB complex; see profile viewer"}
                print("SKIP isolated conformer for %s: exact experimental complex is integrated in its profile"%name)
                continue
            atoms,bonds,method=pubchem_conformer(item)
            asset=os.path.join(ROOT,"drugs",slug+".glb")
            os.makedirs(os.path.dirname(asset),exist_ok=True)
            glb(asset,atoms,bonds,name)
            manifest[slug]={**item,"asset":asset,"atom_count":len(atoms),"bond_count":len(bonds),
              "coordinate_method":method,"structure_status":"3D conformer generated",
              "scientific_note":"This is an isolated-molecule conformer, not an experimentally observed receptor-bound pose."}
            print("OK %s: %d atoms, %d bonds (%s)"%(name,len(atoms),len(bonds),method))
        except Exception as e:
            failures.append({"drug":name,"error":str(e)})
            manifest[slug]={**item,"asset":None,"structure_status":"generation failed","error":str(e)}
            print("FAILED %s: %s"%(name,e))
        time.sleep(1.4)
    # Add predicted, unbound target-protein structures from AlphaFold DB where a
    # single protein target is scientifically appropriate and a UniProt accession exists.
    target_cache={}
    for item in catalog:
        accession=item.get("uniprot")
        if not accession or item.get("experimental_complex_only"):
            continue
        if accession not in target_cache:
            try:
                meta=json.loads(get("https://alphafold.ebi.ac.uk/api/prediction/"+accession))
                if not meta:
                    raise RuntimeError("No AlphaFold DB model returned")
                pdb_url=meta[0].get("pdbUrl")
                if not pdb_url:
                    raise RuntimeError("AlphaFold response has no PDB URL")
                pdb=get(pdb_url).decode("utf-8","replace")
                protein_atoms=[]
                for line in pdb.splitlines():
                    if not line.startswith("ATOM  ") or len(line)<78:
                        continue
                    element=line[76:78].strip().upper()
                    if element in ("H","D"):
                        continue
                    try:
                        xyz=(float(line[30:38]),float(line[38:46]),float(line[46:54]))
                    except ValueError:
                        continue
                    residue=line[17:20].strip()
                    chain=line[21:22].strip() or "A"
                    seq=line[22:26].strip()+line[26:27].strip()
                    atom_name="%s_%s_%s_%s"%(residue,chain,seq,line[12:16].strip())
                    protein_atoms.append({"xyz":xyz,"element":element,"name":atom_name})
                if not protein_atoms:
                    raise RuntimeError("AlphaFold PDB contained no heavy atoms")
                target_path=os.path.join(ROOT,"targets",accession+".glb")
                os.makedirs(os.path.dirname(target_path),exist_ok=True)
                glb(target_path,protein_atoms,[],"AlphaFold target "+accession)
                target_cache[accession]={"asset":target_path,"pdb_url":pdb_url,
                    "atom_count":len(protein_atoms),"source":"AlphaFold DB predicted monomer"}
                print("TARGET %s: %d heavy atoms -> %s"%(accession,len(protein_atoms),target_path))
            except Exception as e:
                target_cache[accession]={"asset":None,"error":str(e)}
                print("TARGET MODEL UNAVAILABLE %s: %s"%(accession,e))
        record=target_cache[accession]
        item_slug=item["slug"]
        if item_slug in manifest:
            manifest[item_slug]["target_asset"]=record.get("asset")
            manifest[item_slug]["target_structure_source"]=record.get("source")
            manifest[item_slug]["target_atom_count"]=record.get("atom_count")
            if record.get("error"):
                manifest[item_slug]["target_structure_error"]=record["error"]
    with open(os.path.join(ROOT,"drug_manifest.json"),"w") as f: json.dump(manifest,f,indent=2)
    ready=sum(1 for v in manifest.values() if v.get("asset") or v.get("experimental_complex_only"))
    conformers=sum(1 for v in manifest.values() if v.get("asset"))
    experimental=sum(1 for v in manifest.values() if v.get("experimental_complex_only"))
    print("Prepared %d/%d drug 3D structures (%d computed conformers + %d experimental complexes)"%(ready,len(catalog),conformers,experimental))
    print("Unique predicted protein target models: %d/%d"%(sum(1 for v in target_cache.values() if v.get("asset")),len(target_cache)))
    if failures:
        print("Molecular generation failures: "+json.dumps(failures))
        raise SystemExit(1)
if __name__=="__main__": main()
