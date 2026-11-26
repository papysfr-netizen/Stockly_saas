const {chromium}=require('playwright');const fs=require('fs');
const nom=process.argv[2], fps=+(process.argv[3]||30), seul=process.argv[4];
const duree=JSON.parse(fs.readFileSync('durees.json'))[nom];
(async()=>{const b=await chromium.launch();const p=await b.newPage({viewport:{width:540,height:960},deviceScaleFactor:2});
await p.goto('file://'+process.cwd()+'/'+nom+'.html');await p.evaluate(()=>document.fonts.ready);
fs.mkdirSync('img_'+nom,{recursive:true});
if(seul){for(const t of seul.split(',')){await p.evaluate(t=>rendre(t),+t);await p.screenshot({path:`apercu_${nom}_${t}.png`});}await b.close();return;}
const n=Math.round(duree*fps);
for(let i=0;i<n;i++){await p.evaluate(t=>rendre(t),i/fps);await p.screenshot({path:`img_${nom}/${String(i).padStart(4,'0')}.jpg`,type:'jpeg',quality:90});}
await b.close();})();
