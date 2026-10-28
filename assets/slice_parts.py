"""Import original articulated atlas: crop, fit and pad only, no repainting."""
from pathlib import Path
from PIL import Image
import json,hashlib
root=Path(__file__).resolve().parent
source=Image.open(root/'original/parts-atlas.png').convert('RGBA')
names=['seed_base','seed_head','flower_base','flower_head','runner_body','runner_leg_l','runner_leg_r','armor_body','armor_leg_l','armor_leg_r','heart_base','heart_core','petal','restored_plant','bud','reserve_module']
manifest=[]
for i,name in enumerate(names):
    col,row=i%4,i//4
    rect=[col*384,row*256,(col+1)*384,(row+1)*256]
    if name=='runner_body': rect[2]=420
    if name=='runner_leg_l': rect[0]=420
    cell=source.crop(rect)
    bbox=cell.getchannel('A').point(lambda v:255 if v>32 else 0).getbbox()
    if not bbox: raise ValueError(name)
    part=cell.crop(bbox)
    factor=min(220/part.width,210/part.height)
    part=part.resize((round(part.width*factor),round(part.height*factor)),Image.Resampling.LANCZOS)
    canvas=Image.new('RGBA',(256,256))
    anchor=[128,128]
    y=(256-part.height)//2
    if name.endswith('_base'):
        y=234-part.height; anchor=[128,234]
    elif '_leg_' in name:
        y=20; anchor=[128,20]
    canvas.alpha_composite(part,((256-part.width)//2,y))
    target=root/'parts'/(name+'.png'); canvas.save(target)
    manifest.append({'name':name,'source_rect':rect,'alpha_bbox':bbox,'anchor':anchor,'scale':factor,'size':part.size,'sha256':hashlib.sha256(target.read_bytes()).hexdigest()})
(root/'parts-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print(json.dumps({'parts':len(manifest),'source_size':source.size,'transparent_corner':source.getpixel((0,0))[3],'all_output_corners_transparent':all(Image.open(root/'parts'/(n+'.png')).getpixel((0,0))[3]==0 for n in names)}))
