const {chromium}=require('playwright');const fs=require('fs');
const nom=process.argv[2], fps=30, c=JSON.parse(fs.readFileSync('calage.json'))[nom];
const interp=(x,X,Y)=>{if(x<=X[0])return Y[0];for(let i=1;i<X.length;i++)if(x<=X[i])return Y[i-1]+(Y[i]-Y[i-1])*(x-X[i-1])/(X[i]-X[i-1]);return Y[Y.length-1];};
const duree=c.reel[c.reel.length-1];
(async()=>{const b=await chromium.launch();const p=await b.newPage({viewport:{width:540,height:960},deviceScaleFactor:2});
await p.goto('file://'+process.cwd()+'/'+nom+'.html');await p.evaluate(()=>document.fonts.ready);
fs.rmSync('img_'+nom,{recursive:true,force:true});fs.mkdirSync('img_'+nom);
const n=Math.round(duree*fps);
for(let i=0;i<n;i++){const t=interp(i/fps,c.reel,c.anim);await p.evaluate(t=>rendre(t),t);await p.screenshot({path:`img_${nom}/${String(i).padStart(4,'0')}.jpg`,type:'jpeg',quality:90});}
await b.close();})();
