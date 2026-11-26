import json,sys,re,subprocess,wave,numpy as np
sys.argv=[sys.argv[0],'x','1','']  # neutralise l'entrée de musique.py
import importlib.util
spec=importlib.util.spec_from_file_location('m','musique.py')
src=open('musique.py').read().split("video, duree, dings")[0]
m={};exec(src,m)
SR=44100
cal=json.load(open('calage.json'))
for nom,c in cal.items():
    duree=c['reel'][-1]; f=lambda a: float(np.interp(a,c['anim'],c['reel']))
    html=open(nom+'.html').read()
    mus=m['musique'](duree); mus*=0.22/np.max(np.abs(mus))   # musique baissée sous la voix
    sfx=np.zeros_like(mus)
    dern=-1
    for t in sorted({float(x) for x in re.findall(r'data-in="([\d.]+)" data-fx="pop"',html)}):
        r=f(t)
        if r-dern>0.15: m['place'](sfx,m['pop'](),r,0.18); dern=r
    for t in sorted({float(x) for x in re.findall(r'data-out="([\d.]+)"',html)}):
        if t<17: m['place'](sfx,m['whoosh'](),max(0,f(t)-0.35),0.16)
    for t in c['dings']: m['place'](sfx,m['ding'](),f(t),0.22)
    pcm=subprocess.run(['ffmpeg','-v','error','-i',f'voix/{nom}.mp3','-ac','2','-ar',str(SR),'-f','s16le','-'],capture_output=True).stdout
    v=np.frombuffer(pcm,'<i2').reshape(-1,2).astype(float)/32768
    v*=0.8/np.max(np.abs(v)); voix=np.zeros_like(mus); m['place'](voix,v[:,0],0.3,1.0)
    # « ducking » : la musique s'efface un peu plus quand la voix parle
    env=np.abs(voix[:,0]); k=int(0.15*SR); env=np.convolve(env,np.ones(k)/k,'same'); g=1-0.45*np.clip(env/0.08,0,1)
    mix=mus*g[:,None]+sfx+voix
    m['ecrire'](nom+'.wav',mix); print(nom,round(duree,1),'s')
