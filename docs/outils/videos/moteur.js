const cl=(x)=>Math.max(0,Math.min(1,x));
const eo=(x)=>1-Math.pow(1-x,3);
const back=(x)=>{const c=1.7;return 1+(c+1)*Math.pow(x-1,3)+c*Math.pow(x-1,2);};
window.rendre=function(t){
  document.querySelectorAll('.a').forEach(el=>{
    const i=+el.dataset.in||0, o=el.dataset.out?+el.dataset.out:1e9, fx=el.dataset.fx||'fade';
    const pi=cl((t-i)/0.5), po=cl((t-(o-0.35))/0.35);
    let e=fx==='pop'?back(pi):eo(pi);
    el.style.opacity=(cl(pi*1.6))*(1-po);
    let tr='';
    if(fx==='up')tr=`translateY(${(1-e)*50}px)`;
    if(fx==='left')tr=`translateX(${(1-e)*-80}px)`;
    if(fx==='right')tr=`translateX(${(1-e)*80}px)`;
    if(fx==='zoom'||fx==='pop')tr=`scale(${0.6+0.4*e})`;
    if(el.dataset.pulse){const p=+el.dataset.pulse; if(t>p&&t<o) tr+=` scale(${1+0.05*Math.sin((t-p)*9)})`;}
    el.style.transform=tr;
  });
  document.querySelectorAll('[data-type]').forEach(el=>{
    const [t0,d]=el.dataset.type.split(',').map(Number); const s=el.dataset.texte;
    const n=Math.round(cl((t-t0)/d)*s.length); el.textContent=s.slice(0,n);
  });
  document.querySelectorAll('[data-count]').forEach(el=>{
    const [a,b,t0,d]=el.dataset.count.split(',').map(Number);
    const v=a+(b-a)*eo(cl((t-t0)/d)); el.textContent=Math.round(v).toLocaleString('fr-FR').replace(/ /g,' ')+(el.dataset.suffixe||'');
  });
};
