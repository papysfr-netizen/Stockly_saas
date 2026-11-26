# Musique originale « soukous » + bruitages, synthétisés (aucun extrait d'œuvre existante)
import numpy as np, wave, re, sys, json
SR=44100
def midi(n): return 440*2**((n-69)/12)
rng=np.random.default_rng(7)

def ks(f, dur, decay=0.996, bright=1.0):
    N=max(2,int(SR/f)); n=int(dur*SR)
    y=np.zeros(n+N+1); y[:N]=rng.uniform(-1,1,N)*bright
    i=N+1
    while i<len(y):
        j=min(i+N,len(y))
        y[i:j]=decay*0.5*(y[i-N:j-N]+y[i-N-1:j-N-1]); i=j
    out=y[N+1:N+1+n]
    env=np.ones(n); r=min(n,int(0.02*SR)); env[-r:]=np.linspace(1,0,r)
    return out*env

def place(buf, sig, t, g=1.0, pan=0.0):
    i=int(t*SR)
    if i>=buf.shape[0]: return
    s=sig[:buf.shape[0]-i]*g
    buf[i:i+len(s),0]+=s*(1-pan)/1; buf[i:i+len(s),1]+=s*(1+pan)/1

def musique(duree, bpm=116):
    n=int(duree*SR); buf=np.zeros((n,2))
    b=60/bpm; s16=b/4
    accords=[(57,[69,73,76,81]),(62,[69,74,78,81]),(64,[68,71,76,80]),(62,[69,74,78,81])]  # A D E D
    motif=[0,1,2,1,2,3,2,1,0,1,2,3,2,1,0,2]
    nb_mesures=int(duree/(4*b))+1
    t_k=np.arange(int(0.3*SR))/SR
    kick=np.sin(2*np.pi*(50*t_k+70*(1-np.exp(-t_k*30))/30*1))*np.exp(-t_k*14)
    tn=np.arange(int(0.14*SR))/SR
    caisse_cl=(rng.uniform(-1,1,len(tn))*0.7+0.4*np.sin(2*np.pi*190*tn))*np.exp(-tn*28)
    th=np.arange(int(0.05*SR))/SR
    hh=np.diff(rng.uniform(-1,1,len(th)+1))*np.exp(-th*90)
    for m in range(nb_mesures):
        base, tons=accords[m%4]; t0=m*4*b
        lead_on = m>=1
        for k in range(16):
            t=t0+k*s16
            if t>=duree: break
            # charleston (shaker) en doubles croches, accent sur les contretemps
            place(buf,hh,t,0.10 if k%2 else 0.05, pan=0.3)
            if lead_on:
                f=midi(tons[motif[k]]); acc=1.0 if k%4==0 else 0.75
                place(buf,ks(f,0.45,0.9965,acc),t,0.20,pan=0.35)
        for beat in range(4):
            t=t0+beat*b
            if t>=duree: break
            if beat in (0,2): place(buf,kick,t,0.55)
            if beat in (1,3): place(buf,caisse_cl,t,0.22,pan=-0.1)
            # guitare rythmique : accords sur les contretemps
            tc=t+b/2
            if tc<duree:
                for nn in tons[:3]:
                    place(buf,ks(midi(nn-12),0.18,0.985,0.8),tc,0.07,pan=-0.4)
        place(buf,kick,t0+2.75*b,0.35)
        # basse : fondamentale, quinte, fondamentale
        for (tb,deg) in [(0,0),(1.5,7),(2,0),(3,12),(3.5,7)]:
            t=t0+tb*b
            if t>=duree: continue
            d=0.35; tt=np.arange(int(d*SR))/SR; f=midi(base-24+deg)
            bas=(np.sin(2*np.pi*f*tt)+0.35*np.sin(4*np.pi*f*tt))*np.exp(-tt*6)*np.minimum(1,tt*200)
            place(buf,bas,t,0.40)
    # fondu
    fi=int(0.3*SR); fo=int(1.5*SR)
    buf[:fi]*=np.linspace(0,1,fi)[:,None]; buf[-fo:]*=np.linspace(1,0,fo)[:,None]
    return buf

def pop():
    t=np.arange(int(0.09*SR))/SR; f=500+900*t/0.09
    return np.sin(2*np.pi*np.cumsum(f)/SR)*np.exp(-t*35)
def whoosh():
    d=0.45; n=int(d*SR); x=rng.uniform(-1,1,n); y=np.zeros(n); a=0.0
    for i in range(n):
        al=0.02+0.5*(i/n)**1.5 if i<n*0.6 else 0.02+0.5*((n-i)/n/0.4)**1.5
        a+= al*(x[i]-a); y[i]=a
    env=np.sin(np.pi*np.arange(n)/n)**2
    return y*env*2.2
def ding():
    t=np.arange(int(1.0*SR))/SR
    return (np.sin(2*np.pi*1318*t)+0.6*np.sin(2*np.pi*1976*t)+0.25*np.sin(2*np.pi*2637*t))*np.exp(-t*4.5)*0.6

def ecrire(nom, buf):
    pk=np.max(np.abs(buf)); buf=np.tanh(buf/pk*1.1)/np.tanh(1.1)*0.89
    data=(buf*32767).astype('<i2')
    with wave.open(nom,'wb') as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes(data.tobytes())

video, duree, dings = sys.argv[1], float(sys.argv[2]), [float(x) for x in sys.argv[3].split(',') if x]
html=open(video+'.html').read()
mus=musique(duree)
mus*=0.55/np.max(np.abs(mus))
sfx=np.zeros_like(mus)
pops=sorted({round(float(m),2) for m in re.findall(r'data-in="([\d.]+)" data-fx="pop"',html)})
dern=-1
for t in pops:
    if t-dern>0.15: place(sfx,pop(),t,0.35); dern=t
outs=sorted({float(m) for m in re.findall(r'data-out="([\d.]+)"',html)})
for t in outs:
    if t<duree-1: place(sfx,whoosh(),max(0,t-0.35),0.30)
for t in dings: place(sfx,ding(),t,0.40)
ecrire(video+'.wav', mus+sfx)
print(video,'pops',len(pops),'whoosh',len([o for o in outs if o<duree-1]))
