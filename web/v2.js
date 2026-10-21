'use strict';
(() => {
  const $ = id => document.getElementById(id), copy = v => JSON.parse(JSON.stringify(v));
  const words = {
    cycles:['Weercycli','Weather cycles'], regions:['Gebieden','Regions'], effects:['Temperatuur','Temperature'],
    title:['Omgeving ontwerpen','Design your environment'], reload:['Opnieuw laden','Reload'], new:['Nieuw','New'],
    save:['Opslaan','Save'], activate:['Globaal activeren','Activate globally'], stop:['Globale cyclus stoppen','Stop global cycle'],
    remove:['Verwijderen','Delete'], duplicate:['Dupliceren','Duplicate'], name:['Naam','Name'], start:['Starttijd','Start time'],
    add:['Blok toevoegen','Add block'], weather:['Weertype','Weather type'], percent:['Deel van de speldag (%)','Share of game day (%)'],
    transition:['Overgang (spelseconden)','Transition (game seconds)'], temperature:['Temperatuur (°C)','Temperature (°C)'],
    up:['Omhoog','Up'], down:['Omlaag','Down'], total:['Totaal','Total'], paused:['Gepauzeerd','Paused'],
    seconds:['echte seconden','real seconds'], minutes:['spelminuten','game minutes'], day:['Dagindeling','Day timeline'],
    active:['Actieve globale cyclus','Active global cycle'], none:['Geen','None'], dirty:['Niet-opgeslagen wijzigingen','Unsaved changes'],
    saved:['Opgeslagen','Saved'], locked:['Opslag geblokkeerd. Controleer de serverconsole.','Storage locked. Check the server console.'],
    discard:['Niet-opgeslagen wijzigingen weggooien?','Discard unsaved changes?'], confirm:['Bevestigen','Confirm'], cancel:['Annuleren','Cancel'],
    deleteConfirm:['Dit opgeslagen item verwijderen?','Delete this saved item?'], stopConfirm:['Globale cyclus stoppen en het huidige doelweer vasthouden?','Stop the global cycle and retain its target weather?'],
    stopForManual:['Deze actie stopt de globale weercyclus. Doorgaan? Gebieden blijven hun eigen weer gebruiken.','This action stops the global weather cycle. Continue? Regions keep their own weather.'],
    cycleBlocked:['Een cyclus is actief. De hoofdadmin kan deze stoppen in Weercycli.','A cycle is active. The superadmin can stop it under Weather cycles.'],
    cycleHelp:['Een speldag is 100%. De overgang hoort bij het begin van ieder blok. Opslaan wijzigt een actieve cyclus direct.','A game day is 100%. Each transition is included at the start of its block. Saving changes an active cycle immediately.'],
    invalidTotal:['Gebruik 1–24 blokken met samen exact 100%, maximaal twee decimalen.','Use 1–24 blocks totaling exactly 100%, with at most two decimals.'],
    mode:['Weermodus','Weather mode'], static:['Vast weer','Static weather'], weighted:['Gewogen dynamisch','Weighted dynamic'],
    cycle:['Weercyclus','Weather cycle'], enabled:['Gebied ingeschakeld','Region enabled'], border:['Gebiedsovergang (echte seconden)','Region transition (real seconds)'],
    interval:['Dynamisch interval (echte minuten)','Dynamic interval (real minutes)'], weights:['Weerkansen (relatieve gewichten)','Weather chances (relative weights)'],
    mapHelp:['Schematische kaart, noord boven. Teken punten of een rechthoek; sleep punten in Bewerken. Gebruik je positie of exacte coördinaten voor precieze grenzen.','Schematic map, north up. Draw points or a rectangle; drag points in Edit. Use your position or exact coordinates for precise boundaries.'],
    draw:['Veelhoek tekenen','Draw polygon'], rectangle:['Rechthoek','Rectangle'], edit:['Punten bewerken','Edit vertices'], move:['Gebied verplaatsen','Move region'],
    select:['Selecteren','Select'], pan:['Kaart verschuiven','Pan map'], undo:['Laatste punt weg','Remove last point'], clear:['Punten wissen','Clear vertices'],
    position:['Mijn positie toevoegen','Add my position'], center:['Naar mijn positie','Center on my position'], reset:['Kaart herstellen','Reset map'],
    coordinates:['Punten / wereldcoördinaten','Vertices / world coordinates'], regionHelp:['Buiten de gebieden geldt het globale weer. Gebieden mogen niet overlappen. Hoogte telt niet mee.','Global weather applies outside regions. Regions cannot overlap. Altitude is not used.'],
    fallback:['Globale temperatuur (°C)','Global temperature (°C)'], heat:['Hittetrilling inschakelen','Enable heat haze'], cold:['Vorstranden inschakelen','Enable frost edges'],
    heatThreshold:['Warm vanaf (°C)','Heat starts at (°C)'], coldThreshold:['Koud onder (°C)','Cold below (°C)'],
    intensity:['Maximale intensiteit (0–1)','Maximum intensity (0–1)'], fade:['Effectopbouw (echte seconden)','Effect fade (real seconds)'],
    effectHelp:['Alleen visuele effecten, voor iedereen. Geen gezondheidsschade. Hitte geeft voorrang aan andere actieve timecycle-effecten; schakel hitte uit en weer aan om opnieuw te proberen.','Visual effects only, for everyone. No health damage. Heat yields to other active timecycle effects; toggle heat off and on to retry.'],
    preview:['Tijdlijnvoorbeeld','Timeline preview'], loading:['Gegevens laden…','Loading data…'], global:['Globaal / buiten gebieden','Global / outside regions'],
    current:['Jouw omgeving','Your environment'], useSaved:['Sla je wijzigingen eerst op.','Save your changes first.'],
    globalControl:['Deze bediening wijzigt het globale weer. Gebieden behouden hun eigen weerinstellingen.','These controls change global weather. Regions retain their own weather settings.'],
    invalid:['Ongeldige invoer. Controleer waarden, grenzen en cycluskoppelingen.','Invalid input. Check values, boundaries and cycle references.'],
    revision:['De gegevens zijn gewijzigd. Herlaad om de nieuwste versie te bekijken; je invoer is behouden.','Data changed. Reload to view the latest version; your input was retained.'],
    overlap:['Dit gebied overlapt een ander gebied.','This region overlaps another region.'],
    in_use:['Deze cyclus is in gebruik. Stop de globale cyclus en verwijder gebiedskoppelingen eerst.','This cycle is in use. Stop the global cycle and remove region references first.'],
    storage:['Opslaan mislukt. De server heeft je wijziging niet bevestigd.','Save failed. The server did not confirm your change.'],
    forbidden:['Geen hoofdadminrechten.','Superadmin permission required.'],
    chooseCycle:['Kies een opgeslagen cyclus','Choose a saved cycle'], saveFirst:['Sla eerst een cyclus op bij Weercycli.','Save a cycle under Weather cycles first.'],
    presets:['Voorbeeldgebieden','Example regions'], sandy:['Zonnig Sandy Shores','Sunny Sandy Shores'], north:['Regenachtig noorden','Rainy north'],
    reloaded:['Opnieuw geladen','Reloaded'], id:['Vaste code','Stable ID'], localOnly:['Voorbeeld — nog niet opgeslagen','Preview — not saved yet']
  };
  const t = key => words[key]?.[window.MSTRLocale.language === 'en' ? 1 : 0] || key;
  let snapshot=null, docs={}, page=null, dirty=false, selectedCycle='', selectedRegion='', lang='', confirmResolve=null;
  let cycleDraft=null, regionDraft=null, effectDraft=null, mapTool='select', view=[-4500,-8000,9000,12000], drag=null, rectangleStart=null;
  let dirtyPages={};
  const weatherTypes=['EXTRASUNNY','CLEAR','CLOUDS','SMOG','FOGGY','OVERCAST','RAIN','THUNDER','CLEARING','NEUTRAL','SNOW','SNOWLIGHT','BLIZZARD','XMAS','HALLOWEEN'];
  const text = (id,value) => { if ($(id)) $(id).textContent=value; };
  const input = (id,label,type='text',extra='') => `<label>${t(label)}<input id="${id}" type="${type}" ${extra}></label>`;
  const button = (id,label) => `<button type="button" id="${id}">${t(label)}</button>`;
  const id = prefix => prefix+'_'+Date.now().toString(36)+'_'+Math.random().toString(36).slice(2,6);
  const newCycle = () => ({version:2,name:t('new'),startMinute:0,blocks:[{weather:'CLEAR',percent:50,transitionGameSeconds:120,temperature:24},{weather:'RAIN',percent:50,transitionGameSeconds:120,temperature:16}]});
  const newRegion = () => ({name:t('new'),enabled:true,points:[],mode:'static',weather:'EXTRASUNNY',cycle:'',temperature:30,transitionSeconds:15,intervalMinutes:15,weights:{CLEAR:40,CLOUDS:30,RAIN:30}});
  const nav=document.querySelector('nav');
  for (const key of ['cycles','regions','effects']) {
    const b=document.createElement('button');b.dataset.page=key;b.dataset.permission='manage';b.dataset.noLocalize='';b.hidden=true;b.textContent=t(key);nav.append(b);
    const s=document.createElement('section');s.className='page v2-page';s.id=key;s.hidden=true;s.dataset.noLocalize='';document.querySelector('footer').before(s);
  }
  const local=document.createElement('p');local.id='v2-local';local.dataset.noLocalize='';$('dashboard').append(local);
  const globalNote=document.createElement('p');globalNote.dataset.noLocalize='';globalNote.id='v2-global-note';$('weather').prepend(globalNote);
  const modal=document.createElement('div');modal.id='v2-confirm';modal.hidden=true;modal.dataset.noLocalize='';
  modal.innerHTML='<div role="dialog" aria-modal="true"><p id="v2-confirm-text"></p><div class="button-row"><button id="v2-confirm-yes"></button><button id="v2-confirm-no"></button></div></div>';
  $('app').append(modal);
  function finishConfirm(value) {modal.hidden=true;const fn=confirmResolve;confirmResolve=null;fn?.(value);}
  $('v2-confirm-yes').onclick=()=>finishConfirm(true);$('v2-confirm-no').onclick=()=>finishConfirm(false);
  function confirm(message) {finishConfirm(false);text('v2-confirm-text',message);text('v2-confirm-yes',t('confirm'));text('v2-confirm-no',t('cancel'));modal.hidden=false;$('v2-confirm-no').focus();return new Promise(resolve=>{confirmResolve=resolve;});}
  const frost=document.createElement('div');frost.id='v2-frost';frost.hidden=true;frost.setAttribute('aria-hidden','true');document.body.append(frost);
  window.addEventListener('message',event=>{if(event.data?.action==='temperature'){const n=Math.max(0,Math.min(1,Number(event.data.cold)||0));frost.hidden=n===0;frost.style.opacity=n;}});
  function mark(){dirty=true;text('v2-dirty',t('dirty'));}
  async function discard(){return !dirty||await confirm(t('discard'));}
  function choose(select,items,value){select.replaceChildren(...items.map(([label,key])=>new Option(label,key)));select.value=value;}
  function weatherSelect(element,value){choose(element,weatherTypes.map(w=>[window.MSTRLocale.t(w),w]),value);}
  async function request(kind,op,payload={}) { return window.MSTRControls.send('v2',{kind,op,...payload}); }
  function toolbar(root) {
    document.querySelectorAll('.v2-page').forEach(s=>{if(s!==root)s.replaceChildren();});
    root.innerHTML=`<div class="section-heading"><div><div class="eyebrow">MSTR · V2</div><h3 class="section-title">${t(page)}</h3></div>${button('v2-reload','reload')}</div><p id="v2-dirty"></p><div id="v2-content"></div>`;
    $('v2-reload').onclick=async()=>{if(!(dirty||Object.values(dirtyPages).some(Boolean))||await confirm(t('discard'))) {await request('all','list');}};
    text('v2-dirty',dirty?t('dirty'):t('saved'));
  }
  function capture() {
    if(page==='cycles'&&cycleDraft&&$('cycle-name')){
      cycleDraft.name=$('cycle-name').value;cycleDraft.startMinute=Number($('cycle-start').value.split(':')[0])*60+Number($('cycle-start').value.split(':')[1]);
      document.querySelectorAll('[data-block]').forEach(row=>{
        const b=cycleDraft.blocks[Number(row.dataset.block)];b.weather=row.querySelector('[data-field="weather"]').value;
        for(const key of ['percent','transitionGameSeconds','temperature']) b[key]=Number(row.querySelector(`[data-field="${key}"]`).value);
      });
    }
    if(page==='regions'&&regionDraft&&$('region-name')){
      regionDraft.name=$('region-name').value;regionDraft.enabled=$('region-enabled').checked;regionDraft.mode=$('region-mode').value;
      regionDraft.weather=$('region-weather').value;regionDraft.cycle=$('region-cycle').value;
      for(const [field,key] of [['temperature','region-temp'],['transitionSeconds','region-transition'],['intervalMinutes','region-interval']]) regionDraft[field]=Number($(key).value);
      regionDraft.weights=Object.fromEntries([...document.querySelectorAll('[data-weight]')].map(e=>[e.dataset.weight,Number(e.value)]));
    }
    if(page==='effects'&&effectDraft&&$('effect-heat')){
      effectDraft.heat=$('effect-heat').checked;effectDraft.cold=$('effect-cold').checked;
      for(const k of ['heatThreshold','coldThreshold','intensity','fadeSeconds','fallbackTemperature']) effectDraft[k]=Number($('effect-'+k).value);
    }
  }
  const clock = seconds => {const m=Math.floor(((seconds%86400)+86400)%86400/60);return String(Math.floor(m/60)).padStart(2,'0')+':'+String(m%60).padStart(2,'0');};
  function timeline(){
    capture();let total=0,start=cycleDraft.startMinute*60;
      const strip=$('cycle-timeline');strip.replaceChildren();const details=$('cycle-timings');details.replaceChildren();
    cycleDraft.blocks.forEach((b,i)=>{
      const icon=document.querySelector(`[data-block="${i}"] .v2-mini-icon`);if(icon&&window.MSTRWeatherSVG)icon.innerHTML=window.MSTRWeatherSVG(b.weather);
      total+=Math.round(b.percent*100);const duration=b.percent*864;const piece=document.createElement('div');
      piece.style.flexGrow=String(Math.max(0,b.percent));piece.style.background=`hsl(${195+i*33} 35% 42%)`;piece.textContent=window.MSTRLocale.t(b.weather);piece.title=b.percent+'%';strip.append(piece);
      const line=document.createElement('p');const speed=snapshot?.state?.timeScale||0;
      line.textContent=`${i+1}. ${clock(start)} → ${clock(start+duration)} · ${b.percent}% · ${Math.round(duration/60)} ${t('minutes')} · ${b.transitionGameSeconds} s → ${snapshot?.state?.timeFrozen||speed===0?t('paused'):(b.transitionGameSeconds/speed).toFixed(1)+' '+t('seconds')}`;
      details.append(line);start+=duration;
    });
    text('cycle-total',`${t('total')}: ${(total/100).toFixed(2)}%`);$('cycle-total').classList.toggle('v2-invalid',total!==10000);
  }
  function renderCycles(){
    if(!cycleDraft) cycleDraft=newCycle();
    const doc=docs.cycles.document;
    $('v2-content').innerHTML=`<p>${t('cycleHelp')}</p><p id="cycle-active"></p><div class="control-box"><div class="control-row"><label>${t('cycles')}<select id="cycle-select"></select></label>${button('cycle-new','new')}${button('cycle-copy','duplicate')}</div><div class="control-row">${input('cycle-name','name','text','maxlength="80" required')}${input('cycle-start','start','time','required')}</div><div id="cycle-blocks"></div><div class="button-row">${button('cycle-add','add')}<strong id="cycle-total"></strong></div><h3>${t('day')}</h3><div id="cycle-timeline"></div><div id="cycle-timings"></div><div class="button-row">${button('cycle-save','save')}${button('cycle-activate','activate')}${button('cycle-stop','stop')}${button('cycle-delete','remove')}</div></div>`;
    choose($('cycle-select'),[[t('new'),''],...Object.entries(doc.cycles).map(([key,c])=>[c.name,key])],selectedCycle);
    $('cycle-name').value=cycleDraft.name;$('cycle-start').value=clock(cycleDraft.startMinute*60);
    text('cycle-active',t('active')+': '+(doc.cycles[doc.active]?.name||t('none')));
    cycleDraft.blocks.forEach((block,i)=>{
      const row=document.createElement('article');row.className='v2-block';row.dataset.block=i;
      row.innerHTML=`<div class="v2-block-heading"><span>${String(i+1).padStart(2,'0')}</span><span class="v2-mini-icon"></span><div class="button-row"><button data-shift="-1">↑</button><button data-shift="1">↓</button><button data-delete>×</button></div></div><div class="control-row"><label>${t('weather')}<select data-field="weather"></select></label><label>${t('percent')}<input data-field="percent" type="number" min="0.01" max="100" step="0.01"></label><label>${t('transition')}<input data-field="transitionGameSeconds" type="number" min="0" step="any"></label><label>${t('temperature')}<input data-field="temperature" type="number" min="-50" max="60" step="any"></label></div>`;
      weatherSelect(row.querySelector('select'),block.weather);
      for(const key of ['percent','transitionGameSeconds','temperature'])row.querySelector(`[data-field="${key}"]`).value=block[key]??20;
      row.querySelector('[data-delete]').title=t('remove');
      row.querySelector('[data-delete]').onclick=()=>{capture();cycleDraft.blocks.splice(i,1);mark();render();};
      row.querySelectorAll('[data-shift]').forEach(b=>{const j=i+Number(b.dataset.shift);b.disabled=j<0||j>=cycleDraft.blocks.length;b.title=t(j<i?'up':'down');b.onclick=()=>{capture();[cycleDraft.blocks[i],cycleDraft.blocks[j]]=[cycleDraft.blocks[j],cycleDraft.blocks[i]];mark();render();};});
      if(window.MSTRWeatherSVG)row.querySelector('.v2-mini-icon').innerHTML=window.MSTRWeatherSVG(block.weather);
      $('cycle-blocks').append(row);
    });
    $('cycle-select').onchange=async e=>{const key=e.target.value;if(!await discard()){e.target.value=selectedCycle;return;}selectedCycle=key;cycleDraft=key?copy(doc.cycles[key]):newCycle();cycleDraft.version=2;cycleDraft.blocks.forEach(b=>b.temperature??=20);dirty=false;render();};
    $('cycle-new').onclick=async()=>{if(await discard()){selectedCycle='';cycleDraft=newCycle();dirty=false;render();}};
    $('cycle-copy').onclick=()=>{capture();selectedCycle='';cycleDraft.name+=' · '+t('duplicate');mark();render();};
    $('cycle-add').disabled=cycleDraft.blocks.length>=24;
    $('cycle-add').onclick=()=>{capture();cycleDraft.blocks.push({weather:'CLEAR',percent:10,transitionGameSeconds:60,temperature:20});mark();render();};
    $('cycle-save').onclick=async()=>{
      capture();const sum=cycleDraft.blocks.reduce((n,b)=>n+Math.round(b.percent*100),0);
      if(sum!==10000||!cycleDraft.blocks.length){text('action-status',t('invalidTotal'));return;}
      const key=selectedCycle||id('cycle');
      const result=await request('cycles','import',{id:key,revision:doc.revision,raw:JSON.stringify({...cycleDraft,version:2})});
      if(result?.ok){selectedCycle=key;cycleDraft=copy(docs.cycles.document.cycles[key]);dirty=false;render();}
    };
    $('cycle-activate').onclick=async()=>{if(dirty||!selectedCycle){text('action-status',t('useSaved'));return;}await request('cycles','activate',{id:selectedCycle,revision:doc.revision});render();};
    $('cycle-stop').onclick=async()=>{if(await confirm(t('stopConfirm'))){await request('cycles','stop',{id:'confirm',revision:doc.revision});render();}};
    $('cycle-delete').onclick=async()=>{if(selectedCycle&&await confirm(t('deleteConfirm'))){const r=await request('cycles','delete',{id:selectedCycle,revision:doc.revision});if(r?.ok){selectedCycle='';cycleDraft=newCycle();dirty=false;render();}}};
    $('cycle-stop').disabled=!doc.active;$('cycle-delete').disabled=!selectedCycle;
    $('v2-content').oninput=()=>{mark();timeline();};timeline();
  }
  function regionOptions(){
    const values=docs.cycles?.document?.cycles||{};
    choose($('region-cycle'),[[t('chooseCycle'),''],...Object.entries(values).map(([key,c])=>[c.name,key])],regionDraft.cycle);
    $('region-cycle-row').hidden=regionDraft.mode!=='cycle';$('region-weights').hidden=regionDraft.mode!=='weighted';
    $('region-static-row').hidden=regionDraft.mode==='cycle';
  }
  function renderRegions(){
    if(!regionDraft)regionDraft=newRegion();const doc=docs.regions.document;
    $('v2-content').innerHTML=`<p>${t('regionHelp')}</p><div class="control-box"><div class="control-row"><label>${t('regions')}<select id="region-select"></select></label>${button('region-new','new')}${button('region-copy','duplicate')}</div><div class="button-row"><span>${t('presets')}</span>${button('region-sandy','sandy')}${button('region-north','north')}</div><div class="control-row">${input('region-name','name','text','maxlength="80" required')}<label>${t('mode')}<select id="region-mode"><option value="static">${t('static')}</option><option value="weighted">${t('weighted')}</option><option value="cycle">${t('cycle')}</option></select></label></div><label class="v2-check"><input type="checkbox" id="region-enabled">${t('enabled')}</label><div class="control-row" id="region-static-row"><label>${t('weather')}<select id="region-weather"></select></label>${input('region-temp','temperature','number','min="-50" max="60" step="any"')}</div><div id="region-cycle-row"><label>${t('cycle')}<select id="region-cycle"></select></label></div><div class="control-row">${input('region-transition','border','number','min="1" max="120" step="any"')}${input('region-interval','interval','number','min="0.1" max="1440" step="any"')}</div><div id="region-weights"><h3>${t('weights')}</h3><div class="v2-weights"></div></div><p>${t('mapHelp')}</p><div class="button-row" id="map-tools"></div><svg id="region-map" viewBox="${view.join(' ')}" role="img" aria-label="${t('regions')}"></svg><p id="map-coord"></p><div class="button-row">${button('map-undo','undo')}${button('map-clear','clear')}${button('map-position','position')}${button('map-center','center')}${button('map-reset','reset')}</div><details><summary>${t('coordinates')}</summary><div id="region-points"></div></details><div class="button-row v2-savebar">${button('region-save','save')}${button('region-delete','remove')}</div></div>`;
    choose($('region-select'),[[t('new'),''],...Object.entries(doc.regions).map(([key,r])=>[r.name,key])],selectedRegion);
    $('region-name').value=regionDraft.name;$('region-enabled').checked=regionDraft.enabled;$('region-mode').value=regionDraft.mode;
    weatherSelect($('region-weather'),regionDraft.weather);
    $('region-temp').value=regionDraft.temperature;$('region-transition').value=regionDraft.transitionSeconds;$('region-interval').value=regionDraft.intervalMinutes;
    for(const w of weatherTypes){const label=document.createElement('label');label.textContent=window.MSTRLocale.t(w);const n=document.createElement('input');n.type='number';n.min=0;n.max=1000000;n.step='any';n.dataset.weight=w;n.value=regionDraft.weights[w]||0;label.append(n);document.querySelector('.v2-weights').append(label);}
    regionOptions();
    $('region-mode').onchange=()=>{capture();mark();regionOptions();};
    $('region-select').onchange=async e=>{const key=e.target.value;if(!await discard()){e.target.value=selectedRegion;return;}selectedRegion=key;regionDraft=key?copy(doc.regions[key]):newRegion();dirty=false;rectangleStart=null;render();};
    $('region-new').onclick=async()=>{if(await discard()){selectedRegion='';regionDraft=newRegion();dirty=false;render();}};
    $('region-copy').onclick=()=>{capture();selectedRegion='';regionDraft.name+=' · '+t('duplicate');regionDraft.points=regionDraft.points.map(p=>({x:p.x+200,y:p.y}));mark();render();};
    for(const preset of ['sandy','north']) $('region-'+preset).onclick=async()=>{
      if(!await discard())return;selectedRegion='';regionDraft=newRegion();regionDraft.name=t(preset);
      if(preset==='sandy'){regionDraft.points=[{x:800,y:2800},{x:2300,y:2800},{x:2300,y:3900},{x:800,y:3900}];regionDraft.temperature=36;}
      else{regionDraft.points=[{x:-1200,y:5500},{x:1200,y:5500},{x:1200,y:7000},{x:-1200,y:7000}];regionDraft.mode='weighted';regionDraft.weather='RAIN';regionDraft.temperature=12;regionDraft.weights={OVERCAST:20,RAIN:65,THUNDER:15};}
      dirty=true;render();text('v2-dirty',t('localOnly'));
    };
    $('region-save').onclick=async()=>{capture();const key=selectedRegion||id('region');const r=await request('regions','save',{id:key,revision:doc.revision,raw:JSON.stringify(regionDraft)});if(r?.ok){selectedRegion=key;regionDraft=copy(docs.regions.document.regions[key]);dirty=false;render();}};
    $('region-delete').disabled=!selectedRegion;$('region-delete').onclick=async()=>{if(await confirm(t('deleteConfirm'))){const r=await request('regions','delete',{id:selectedRegion,revision:doc.revision});if(r?.ok){selectedRegion='';regionDraft=newRegion();dirty=false;render();}}};
    for(const tool of ['select','draw','rectangle','edit','move','pan']){const b=document.createElement('button');b.textContent=t(tool);b.setAttribute('aria-pressed',String(tool===mapTool));b.onclick=()=>{capture();mapTool=tool;rectangleStart=null;render();};$('map-tools').append(b);}
    $('map-undo').onclick=()=>{capture();regionDraft.points.pop();mark();drawMap();pointRows();};
    $('map-clear').onclick=async()=>{if(await confirm(t('clear')+'?')){regionDraft.points=[];mark();drawMap();pointRows();}};
    async function position(){try{const r=await fetch('https://'+GetParentResourceName()+'/position',{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'});return await r.json();}catch{text('action-status',t('invalid'));return null;}}
    $('map-position').onclick=async()=>{const p=await position();if(p&&Number.isFinite(p.x)&&Number.isFinite(p.y)&&regionDraft.points.length<64){regionDraft.points.push({x:+p.x.toFixed(2),y:+p.y.toFixed(2)});mark();drawMap();pointRows();}};
    $('map-center').onclick=async()=>{const p=await position();if(p){view=[p.x-1000,-p.y-1000,2000,2000];drawMap();}};
    $('map-reset').onclick=()=>{view=[-4500,-8000,9000,12000];drawMap();};
    $('v2-content').oninput=e=>{if(!e.target.closest('#region-points')){capture();mark();}};
    bindMap();drawMap();pointRows();
  }
  function svg(tag,attrs={},label){const e=document.createElementNS('http://www.w3.org/2000/svg',tag);for(const [k,v]of Object.entries(attrs))e.setAttribute(k,v);if(label)e.textContent=label;return e;}
  function drawMap(){
    const map=$('region-map');if(!map)return;map.replaceChildren();map.setAttribute('viewBox',view.join(' '));
    // Original schematic outline and world-coordinate grid. No third-party map tiles.
    map.append(svg('path',{d:'M -3700 2600 L -2900 800 L -2600 -900 L -2100 -2600 L -1900 -4500 L -800 -6200 L 300 -7600 L 1700 -6600 L 2900 -4500 L 3600 -2300 L 2800 -100 L 1800 1700 L 700 3200 L -1800 3800 Z',class:'v2-land'}));
    for(let n=-10000;n<=10000;n+=1000){map.append(svg('line',{x1:n,y1:-10000,x2:n,y2:10000,class:'v2-grid'}),svg('line',{x1:-10000,y1:n,x2:10000,y2:n,class:'v2-grid'}));}
    for(const [name,x,y]of [['Los Santos',0,-1000],['Sandy Shores',1600,3500],['Paleto Bay',-150,6400]])map.append(svg('text',{x,y:-y,class:'v2-map-label'},name));
    for(const [key,r]of Object.entries(docs.regions.document.regions))if(key!==selectedRegion)map.append(svg('polygon',{points:r.points.map(p=>`${p.x},${-p.y}`).join(' '),class:'v2-region-other','data-region':key}));
    map.append(svg('polygon',{points:regionDraft.points.map(p=>`${p.x},${-p.y}`).join(' '),class:'v2-region-current'}));
    regionDraft.points.forEach((p,i)=>{map.append(svg('circle',{cx:p.x,cy:-p.y,r:view[2]/100,class:'v2-vertex','data-vertex':i}));});
  }
  function pointRows(){
    $('region-points').replaceChildren();regionDraft.points.forEach((p,i)=>{
      const row=document.createElement('div');row.className='control-row';row.innerHTML=`<span>${i+1}</span><label>X<input type="number" step="any" min="-10000" max="10000" data-axis="x"></label><label>Y<input type="number" step="any" min="-10000" max="10000" data-axis="y"></label><button type="button">×</button>`;
      row.querySelectorAll('input').forEach(e=>{e.value=p[e.dataset.axis];e.oninput=()=>{p[e.dataset.axis]=Number(e.value);mark();drawMap();};});
      row.querySelector('button').title=t('remove');row.querySelector('button').onclick=()=>{regionDraft.points.splice(i,1);mark();drawMap();pointRows();};$('region-points').append(row);
    });
  }
  function bindMap(){
    const map=$('region-map');
    function world(e){const p=map.createSVGPoint();p.x=e.clientX;p.y=e.clientY;const q=p.matrixTransform(map.getScreenCTM().inverse());return{x:Math.max(-10000,Math.min(10000,q.x)),y:Math.max(-10000,Math.min(10000,-q.y))};}
    map.onpointerdown=async e=>{
      const p=world(e);capture();
      if(mapTool==='select'){const key=e.target.dataset.region;if(key&&await discard()){selectedRegion=key;regionDraft=copy(docs.regions.document.regions[key]);dirty=false;render();}return;}
      if(mapTool==='draw'){if(regionDraft.points.length<64){regionDraft.points.push(p);mark();drawMap();pointRows();}return;}
      if(mapTool==='rectangle'){
        if(!rectangleStart){rectangleStart=p;text('map-coord','1 / 2');return;}
        regionDraft.points=[rectangleStart,{x:p.x,y:rectangleStart.y},p,{x:rectangleStart.x,y:p.y}];rectangleStart=null;mark();drawMap();pointRows();return;
      }
      if(mapTool==='edit'&&e.target.dataset.vertex!==undefined)drag={type:'edit',index:Number(e.target.dataset.vertex)};
      else if(mapTool==='move')drag={type:'move',start:p,points:copy(regionDraft.points)};
      else if(mapTool==='pan')drag={type:'pan',x:e.clientX,y:e.clientY,view:[...view]};
      if(drag)map.setPointerCapture(e.pointerId);
    };
    map.onpointermove=e=>{
      const p=world(e);text('map-coord',`X ${p.x.toFixed(1)} · Y ${p.y.toFixed(1)}`);if(!drag)return;
      if(drag.type==='edit')regionDraft.points[drag.index]=p;
      if(drag.type==='move')regionDraft.points=drag.points.map(q=>({x:q.x+p.x-drag.start.x,y:q.y+p.y-drag.start.y}));
      if(drag.type==='pan'){const rect=map.getBoundingClientRect();const scale=Math.max(drag.view[2]/rect.width,drag.view[3]/rect.height);view=[drag.view[0]-(e.clientX-drag.x)*scale,drag.view[1]-(e.clientY-drag.y)*scale,drag.view[2],drag.view[3]];}
      else mark();drawMap();
    };
    map.onpointerup=map.onpointercancel=()=>{drag=null;pointRows();};
    map.addEventListener('wheel',e=>{e.preventDefault();const p=world(e),factor=e.deltaY>0?1.15:1/1.15,w=Math.max(100,Math.min(22000,view[2]*factor)),ratio=w/view[2];view=[p.x+(view[0]-p.x)*ratio,-p.y+(view[1]+p.y)*ratio,w,view[3]*ratio];drawMap();},{passive:false});
  }
  function renderEffects(){
    effectDraft??=copy(docs.regions.document.effects);
    $('v2-content').innerHTML=`<p>${t('effectHelp')}</p><div class="control-box"><div class="checks"><label><input id="effect-heat" type="checkbox">${t('heat')}</label><label><input id="effect-cold" type="checkbox">${t('cold')}</label></div><div class="control-row">${input('effect-heatThreshold','heatThreshold','number','min="-49" max="60" step="any"')}${input('effect-coldThreshold','coldThreshold','number','min="-50" max="59" step="any"')}</div><div class="control-row">${input('effect-intensity','intensity','number','min="0" max="1" step="0.01"')}${input('effect-fadeSeconds','fade','number','min="1" max="120" step="any"')}${input('effect-fallbackTemperature','fallback','number','min="-50" max="60" step="any"')}</div>${button('effect-save','save')}</div>`;
    $('effect-heat').checked=effectDraft.heat;$('effect-cold').checked=effectDraft.cold;
    for(const k of ['heatThreshold','coldThreshold','intensity','fadeSeconds','fallbackTemperature'])$('effect-'+k).value=effectDraft[k];
    $('v2-content').oninput=()=>{capture();mark();};
    $('effect-save').onclick=async()=>{capture();const r=await request('regions','effects',{revision:docs.regions.document.revision,raw:JSON.stringify(effectDraft)});if(r?.ok){dirty=false;effectDraft=copy(docs.regions.document.effects);render();}};
  }
  function render(){
    if(!page||!snapshot?.permissions?.manage)return;toolbar($(page));
    if(!docs.cycles||!docs.regions){text('v2-content',t('loading'));return;}
    if(page==='cycles')renderCycles();else if(page==='regions')renderRegions();else renderEffects();
    const locked=page==='cycles'?docs.cycles.locked:docs.regions.locked;
    if(locked){text('v2-dirty',t('locked'));$('v2-content').querySelectorAll('input,select,button').forEach(e=>e.disabled=true);}
  }
  window.MSTRV2={
    text:t,confirm,error:reason=>words[reason]?t(reason):(reason==='cycle_active'?t('cycleBlocked'):null),
    activeCycle:()=>snapshot?.state?.cycle?.active,cycleRevision:()=>snapshot?.state?.cycle?.revision,
    receive(value){
      if(value.kind==='all'){docs={cycles:value.cycles,regions:value.regions};cycleDraft=selectedCycle?copy(docs.cycles.document.cycles[selectedCycle]||newCycle()):newCycle();regionDraft=selectedRegion?copy(docs.regions.document.regions[selectedRegion]||newRegion()):newRegion();effectDraft=copy(docs.regions.document.effects);dirty=false;dirtyPages={};}
      else docs[value.kind]={document:value.document,locked:value.locked};
      if(value.kind==='all')render();
    },
    update(value){
      snapshot=value;const nextLang=window.MSTRLocale.language;
      text('v2-global-note',t('globalControl'));
      if(!value.permissions?.manage){if(page)document.querySelector('[data-page="dashboard"]').click();docs={};cycleDraft=regionDraft=effectDraft=null;dirty=false;finishConfirm(false);}
      if(nextLang!==lang){capture();lang=nextLang;for(const key of ['cycles','regions','effects'])document.querySelector(`[data-page="${key}"]`).textContent=t(key);render();if(page)text('page-title',t(page));}
      const env=value.localEnvironment;if(env)text('v2-local',`${t('current')}: ${env.region||t('global')} · ${window.MSTRLocale.t(env.weather)} · ${Number(env.temperature).toFixed(1)} °C`);
    },
    page(name){capture();const old=page;page=['cycles','regions','effects'].includes(name)?name:null;
      if(old)dirtyPages[old]=dirty;
      if(page){text('page-title',t(page));if(old!==page)dirty=dirtyPages[page]||false;render();if(!docs.cycles||!docs.regions)request('all','list');}
    },
    close(){capture();page=null;docs={};snapshot=null;cycleDraft=regionDraft=effectDraft=null;dirty=false;dirtyPages={};finishConfirm(false);}
  };
})();
