#!/usr/bin/env python3
"""Build atom-level GLB assets from curated, experimentally determined PDB complexes.

The generated assets retain heavy atoms from the receptor and the named
co-crystallised ligand. No docking pose is invented. Source coordinates are
downloaded from the worldwide Protein Data Bank (RCSB).
"""
import json
import math
import os
import struct
import urllib.request

ROOT = "assets/pharmacology/molecular"
# PDB ID, ligand residue code, short scientific label
STRUCTURES = {
    "ace_lisinopril": ("1O86", "LPR", "Human ACE with lisinopril"),
    "hmgcr_atorvastatin": ("1HWK", "117", "HMG-CoA reductase with atorvastatin"),
    "cox1_ibuprofen": ("1EQG", "IBP", "Cyclo-oxygenase-1 with ibuprofen"),
    "factorxa_apixaban": ("2P16", "GG2", "Factor Xa with apixaban"),
    "dhfr_methotrexate": ("4DFR", "MTX", "Dihydrofolate reductase with methotrexate"),
    "adrb2_carazolol": ("2RH1", "CAU", "Beta-2 adrenergic receptor with carazolol"),
}

ELEMENTS = {
    "C": ([0.66, 0.70, 0.75, 1.0], 0.34),
    "N": ([0.20, 0.42, 0.95, 1.0], 0.32),
    "O": ([0.92, 0.22, 0.20, 1.0], 0.30),
    "S": ([0.96, 0.72, 0.12, 1.0], 0.38),
    "P": ([1.00, 0.48, 0.12, 1.0], 0.38),
    "F": ([0.45, 0.82, 0.40, 1.0], 0.30),
    "CL": ([0.20, 0.75, 0.25, 1.0], 0.38),
    "FE": ([0.80, 0.42, 0.20, 1.0], 0.42),
    "MG": ([0.55, 0.55, 0.70, 1.0], 0.38),
    "ZN": ([0.55, 0.55, 0.65, 1.0], 0.42),
}
WATER = {"HOH", "WAT", "DOD"}

def sphere():
    t = (1.0 + math.sqrt(5.0)) / 2.0
    v = [(-1,t,0),(1,t,0),(-1,-t,0),(1,-t,0),
         (0,-1,t),(0,1,t),(0,-1,-t),(0,1,-t),
         (t,0,-1),(t,0,1),(-t,0,-1),(-t,0,1)]
    n = []
    for x,y,z in v:
        d = math.sqrt(x*x+y*y+z*z); n.append((x/d,y/d,z/d))
    f = [(0,11,5),(0,5,1),(0,1,7),(0,7,10),(0,10,11),
         (1,5,9),(5,11,4),(11,10,2),(10,7,6),(7,1,8),
         (3,9,4),(3,4,2),(3,2,6),(3,6,8),(3,8,9),
         (4,9,5),(2,4,11),(6,2,10),(8,6,7),(9,8,1)]
    for _ in range(2):
        cache = {}
        def mid(a,b):
            key = tuple(sorted((a,b)))
            if key not in cache:
                p = tuple((n[a][i]+n[b][i])/2 for i in range(3))
                d = math.sqrt(sum(x*x for x in p))
                cache[key] = len(n); n.append(tuple(x/d for x in p))
            return cache[key]
        nf = []
        for a,b,c in f:
            ab,bc,ca = mid(a,b),mid(b,c),mid(c,a)
            nf += [(a,ab,ca),(b,bc,ab),(c,ca,bc),(ab,bc,ca)]
        f = nf
    return n, [i for tri in f for i in tri]

def make_glb(atoms, out_path, title):
    if not atoms:
        raise RuntimeError("No atoms parsed for " + title)
    coords = [a[0] for a in atoms]
    center = [sum(p[i] for p in coords)/len(coords) for i in range(3)]
    extent = max(max(abs(p[i]-center[i]) for p in coords) for i in range(3)) or 1.0
    scale = 1.65 / extent
    verts, inds = sphere()
    binary = bytearray()
    views, accessors = [], []
    def add_blob(data, target=None):
        while len(binary) % 4: binary.append(0)
        off = len(binary); binary.extend(data)
        view = {"buffer":0,"byteOffset":off,"byteLength":len(data)}
        if target: view["target"] = target
        views.append(view)
        return len(views)-1
    pos = struct.pack("<" + "f"*len(verts)*3, *[x for p in verts for x in p])
    pos_view = add_blob(pos, 34962)
    accessors.append({"bufferView":pos_view,"componentType":5126,"count":len(verts),"type":"VEC3",
                      "min":[min(p[i] for p in verts) for i in range(3)],
                      "max":[max(p[i] for p in verts) for i in range(3)]})
    idx = struct.pack("<" + "H"*len(inds), *inds)
    idx_view = add_blob(idx, 34963)
    accessors.append({"bufferView":idx_view,"componentType":5123,"count":len(inds),"type":"SCALAR"})
    materials, meshes, nodes = [], [], []
    element_keys = list(ELEMENTS)
    material_index = {}
    for ligand_flag in (False, True):
        for e in element_keys:
            color, _ = ELEMENTS[e]
            if ligand_flag and e == "C":
                color = [0.08, 0.78, 0.82, 1.0]
            label = ("Ligand " if ligand_flag else "Protein ") + e
            material_index[(e, ligand_flag)] = len(materials)
            materials.append({"name":label,"pbrMetallicRoughness":{
                "baseColorFactor":color,"metallicFactor":0.12 if ligand_flag else 0.02,
                "roughnessFactor":0.28 if ligand_flag else 0.48}})
            meshes.append({"name":"Atom "+label,"primitives":[{"attributes":{"POSITION":0},"indices":1,"material":len(materials)-1}]})
    for xyz, element, atom_name, residue, chain, res_seq, is_ligand in atoms:
        el = element if element in ELEMENTS else "C"
        _, radius = ELEMENTS[el]
        nodes.append({
            "name":("%s_%s_%s_%s" % ("LIG" if is_ligand else "PRO", residue, chain, res_seq, atom_name))[:60],
            "mesh":material_index[(el, is_ligand)],
            "translation":[(xyz[i]-center[i])*scale for i in range(3)],
            "scale":[radius*scale*1.35]*3,
        })
    gltf = {
        "asset":{"version":"2.0","generator":"Atlas Academy PDB atom model builder","copyright":"Coordinates: RCSB Protein Data Bank"},
        "scene":0,"scenes":[{"nodes":list(range(len(nodes)))}],
        "nodes":nodes,"meshes":meshes,"materials":materials,
        "buffers":[{"byteLength":len(binary)}],"bufferViews":views,"accessors":accessors,
    }
    js = json.dumps(gltf,separators=(",",":")).encode("utf-8")
    while len(js)%4: js += b" "
    while len(binary)%4: binary.append(0)
    total = 12 + 8 + len(js) + 8 + len(binary)
    with open(out_path,"wb") as f:
        f.write(struct.pack("<4sII",b"glTF",2,total))
        f.write(struct.pack("<I4s",len(js),b"JSON")); f.write(js)
        f.write(struct.pack("<I4s",len(binary),b"BIN\x00")); f.write(binary)

def main():
    os.makedirs(ROOT,exist_ok=True)
    manifest = {}
    for key,(pdb_id,ligand_code,label) in STRUCTURES.items():
        url = "https://files.rcsb.org/download/%s.pdb" % pdb_id
        req = urllib.request.Request(url,headers={"User-Agent":"AtlasAcademy-educational-molecular-viewer/1.0"})
        with urllib.request.urlopen(req,timeout=60) as response:
            pdb = response.read().decode("utf-8","replace")
        atoms=[]
        for line in pdb.splitlines():
            if not (line.startswith("ATOM  ") or line.startswith("HETATM")): continue
            if len(line)<78: continue
            residue=line[17:20].strip()
            chain=line[21:22].strip() or "A"
            if line.startswith("ATOM  ") and chain != "A": continue
            is_ligand=line.startswith("HETATM") and residue==ligand_code
            if line.startswith("HETATM") and not is_ligand: continue
            if residue in WATER: continue
            element=line[76:78].strip().upper()
            if element in ("H","D"): continue
            try: xyz=(float(line[30:38]),float(line[38:46]),float(line[46:54]))
            except ValueError: continue
            res_seq=line[22:26].strip()+line[26:27].strip()
            atoms.append((xyz,element,line[12:16].strip(),residue,chain,res_seq,is_ligand))
        if not any(a[6] for a in atoms):
            raise RuntimeError("Expected co-crystallised ligand %s not found in %s" % (ligand_code,pdb_id))
        path=os.path.join(ROOT,key+".glb")
        make_glb(atoms,path,label)
        ligand_atoms = [a for a in atoms if a[6]]
        ligand_names = ["LIG_%s_%s_%s_%s" % (a[3],a[4],a[5],a[2]) for a in ligand_atoms]
        binding_names = []
        for atom in atoms:
            if atom[6]: continue
            near = any(sum((atom[0][i]-ligand[0][i])**2 for i in range(3)) <= 4.2**2 for ligand in ligand_atoms)
            if near:
                binding_names.append("PRO_%s_%s_%s_%s" % (atom[3],atom[4],atom[5],atom[2]))
        manifest[key]={"pdb_id":pdb_id,"ligand":ligand_code,"label":label,
                       "atom_count":len(atoms),"ligand_atom_count":len(ligand_atoms),
                       "ligand_atom_names":ligand_names,
                       "binding_site_atom_names":sorted(set(binding_names)),
                       "source":url,"asset":path}
        print("%s: %s atoms (%s ligand; %s binding-site atoms) -> %s" % (key,len(atoms),len(ligand_atoms),len(set(binding_names)),path))
    with open(os.path.join(ROOT,"manifest.json"),"w") as f: json.dump(manifest,f,indent=2)

if __name__=="__main__":
    main()
