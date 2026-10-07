(() => {
  'use strict';
  const $ = (s, r=document) => r.querySelector(s);
  const $$ = (s, r=document) => [...r.querySelectorAll(s)];
  const fmt = new Intl.NumberFormat();
  const csrf = $('meta[name="csrf-token"]')?.content || '';
  const base = (window.APP?.baseUrl || '').replace(/\/$/, '');

  function initIcons(){ if(window.lucide) window.lucide.createIcons({attrs:{'stroke-width':1.8}}); }
  function toastAutoHide(){ $$('[data-toast]').forEach(t=>setTimeout(()=>{t.style.opacity='0';t.style.transform='translateY(-8px)';setTimeout(()=>t.remove(),250)},4200)); }
  function initSidebar(){ const menu=$('#menuBtn'),side=$('#sidebar'),back=$('#mobileBackdrop'); if(!menu||!side||!back)return; const close=()=>{side.classList.remove('open');back.classList.remove('show')}; menu.addEventListener('click',()=>{side.classList.toggle('open');back.classList.toggle('show')}); back.addEventListener('click',close); $$('.nav-item',side).forEach(a=>a.addEventListener('click',close)); }
  function openModal(m){ if(!m)return; m.classList.add('open');m.setAttribute('aria-hidden','false');document.body.classList.add('modal-open');setTimeout(()=>m.querySelector('input,select,textarea,button')?.focus(),120); }
  function closeModal(m){ if(!m)return; m.classList.remove('open');m.setAttribute('aria-hidden','true');if(!$('.modal.open'))document.body.classList.remove('modal-open');if(m.id==='taskModal'&&location.hash==='#new-task')history.replaceState(null,'',location.pathname+location.search); }
  function initModals(){ $$('[data-modal-open]').forEach(b=>b.addEventListener('click',()=>openModal(document.getElementById(b.dataset.modalOpen)))); $$('[data-modal-close]').forEach(b=>b.addEventListener('click',()=>closeModal(b.closest('.modal')))); $$('.modal').forEach(m=>m.addEventListener('click',e=>{if(e.target===m)closeModal(m)})); document.addEventListener('keydown',e=>{if(e.key==='Escape')$$('.modal.open').forEach(closeModal)}); }
  function initConfirm(){ $$('[data-confirm]').forEach(el=>el.addEventListener('click',e=>{if(!confirm(el.dataset.confirm||'Are you sure?'))e.preventDefault()})); }
  function initPassword(){ $$('[data-password-toggle]').forEach(btn=>btn.addEventListener('click',()=>{const input=btn.closest('.password-wrap')?.querySelector('input');if(!input)return;input.type=input.type==='password'?'text':'password';btn.innerHTML=input.type==='password'?'<i data-lucide="eye"></i>':'<i data-lucide="eye-off"></i>';initIcons()})); }
  function initTaskEditor(){ $$('[data-task-edit]').forEach(btn=>btn.addEventListener('click',()=>{let data={};try{data=JSON.parse(btn.dataset.taskEdit)}catch{};const m=$('#taskEditModal');if(!m)return;$('#taskEditTitle').textContent=(data.title?'Edit '+data.title:'Edit task');$('#taskEditId').value=data.id||'';$('#taskEditName').value=data.title||'';$('#taskEditDescription').value=data.description||'';$('#taskEditAssignee').value=String(data.primary_assignee_id||'');$('#taskEditCategory').value=data.category_id?String(data.category_id):'';$('#taskEditPriority').value=data.priority||'medium';$('#taskEditDue').value=data.due_at||'';$('#taskEditStatus').value=data.status||'to_do';$('#taskProgress').value=data.progress||0;$('#progressValue').textContent=(data.progress||0)+'%';openModal(m)})); const range=$('#taskProgress');if(range)range.addEventListener('input',()=>$('#progressValue').textContent=range.value+'%'); }
  function syncTaskCreateProgress(){
    const status=$('#taskCreateStatus'), range=$('#taskCreateProgress'), out=$('#taskCreateProgressValue');
    if(!status||!range||!out)return;
    const presets={backlog:0,to_do:0,in_progress:25,blocked:25,in_review:80,completed:100};
    if(document.activeElement===status){ range.value=presets[status.value]??0; }
    if(status.value==='completed') range.value=100;
    out.textContent=range.value+'%';
  }
  function initTaskCreate(){
    const mode=$('#taskAssignmentMode'), empField=$('#taskEmployeeField'), assignee=$('#taskCreateAssignee'), note=$('#assignmentAllNote'), status=$('#taskCreateStatus'), range=$('#taskCreateProgress');
    const syncMode=()=>{if(!mode)return;const all=mode.value==='all';if(empField)empField.hidden=all;if(note)note.hidden=!all;if(assignee)assignee.required=!all;};
    mode?.addEventListener('change',syncMode); syncMode();
    status?.addEventListener('change',syncTaskCreateProgress);range?.addEventListener('input',()=>{$('#taskCreateProgressValue').textContent=range.value+'%'});
    $$('[data-task-duplicate]').forEach(btn=>btn.addEventListener('click',()=>{
      let d={};try{d=JSON.parse(btn.dataset.taskDuplicate||'{}')}catch{}
      const m=$('#taskModal');if(!m)return;
      $('#taskCreateEyebrow').textContent='Duplicate responsibility';$('#taskCreateTitle').textContent='Duplicate task';
      $('#taskCreateName').value=d.title||'';$('#taskCreateDescription').value=d.description||'';$('#taskAssignmentMode').value='single';
      $('#taskCreateAssignee').value=String(d.primary_assignee_id||'');$('#taskCreateCategory').value=d.category_id?String(d.category_id):'';
      $('#taskCreatePriority').value=d.priority||'medium';$('#taskCreateDue').value=d.due_at||'';$('#taskCreateStatus').value=d.status||'to_do';
      $('#taskCreateProgress').value=d.progress||0;$('#taskCreateProgressValue').textContent=(d.progress||0)+'%';syncMode();
      const submit=$('#taskCreateSubmit');if(submit)submit.innerHTML='<i data-lucide="copy-plus"></i>Create duplicate';
      openModal(m);initIcons();setTimeout(()=>$('#taskCreateName')?.focus(),120);
    }));
    $('#new-task')?.addEventListener('click',()=>setTimeout(()=>{
      $('#taskCreateEyebrow').textContent='New responsibility';$('#taskCreateTitle').textContent='Add task';
      const f=$('#taskCreateForm');f?.reset();if(mode)mode.value='single';if(status)status.value='to_do';if(range)range.value=0;
      $('#taskCreateProgressValue').textContent='0%';const submit=$('#taskCreateSubmit');if(submit)submit.innerHTML='<i data-lucide="plus"></i>Create task';syncMode();initIcons();
    },0));
  }
  function initTaskKanban(){
    const board=$('#taskKanban');if(!board||board.dataset.canDrag!=='1')return;
    let dragged=null,origin=null;
    const updateCount=(column)=>{if(!column)return;const count=column.querySelectorAll('[data-task-card]').length;const badge=column.querySelector('[data-column-count]');if(badge)badge.textContent=String(count);const empty=column.querySelector('[data-column-empty]');if(empty)empty.hidden=count>0;};
    $$('[data-task-card]',board).forEach(card=>{
      card.addEventListener('dragstart',e=>{dragged=card;origin=card.closest('.task-column');card.classList.add('is-dragging');e.dataTransfer.effectAllowed='move';e.dataTransfer.setData('text/plain',card.dataset.taskId||'');});
      card.addEventListener('dragend',()=>{card.classList.remove('is-dragging');$$('[data-task-dropzone]',board).forEach(z=>z.classList.remove('is-drag-over'));dragged=null;origin=null;});
    });
    $$('[data-task-dropzone]',board).forEach(zone=>{
      zone.addEventListener('dragover',e=>{if(!dragged)return;e.preventDefault();e.dataTransfer.dropEffect='move';zone.classList.add('is-drag-over')});
      zone.addEventListener('dragleave',e=>{if(!zone.contains(e.relatedTarget))zone.classList.remove('is-drag-over')});
      zone.addEventListener('drop',async e=>{
        e.preventDefault();zone.classList.remove('is-drag-over');if(!dragged)return;
        const card=dragged,originColumn=origin,destination=zone.dataset.taskDropzone,from=card.dataset.taskStatus;if(!destination||destination===from)return;
        const oldParent=card.parentElement,oldNext=card.nextSibling;zone.querySelector('[data-column-empty]')?.setAttribute('hidden','hidden');zone.appendChild(card);
        updateCount(originColumn);updateCount(zone.closest('.task-column'));card.classList.add('is-saving');
        try{
          const body=new URLSearchParams({_csrf:csrf,id:card.dataset.taskId,status:destination});
          const res=await fetch(base+'/handlers/task-move.php',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded;charset=UTF-8','Accept':'application/json'},credentials:'same-origin',body});
          const json=await res.json().catch(()=>({ok:false,message:'Could not read the server response.'}));if(!res.ok||!json.ok)throw new Error(json.message||'Could not move task.');
          card.dataset.taskStatus=destination;card.classList.remove('is-saving');card.classList.add('move-success');setTimeout(()=>location.reload(),420);
        }catch(err){
          card.classList.remove('is-saving');if(oldNext)oldParent.insertBefore(card,oldNext);else oldParent.appendChild(card);updateCount(originColumn);updateCount(zone.closest('.task-column'));alert(err.message||'Could not move task.');
        }
      });
    });
  }

  function initGrowthEditor(){ $$('[data-growth-edit]').forEach(btn=>btn.addEventListener('click',()=>{let d={};try{d=JSON.parse(btn.dataset.growthEdit||'{}')}catch{};const m=$('#growthCountModal');if(!m)return;$('#growthCountTitle').textContent='Edit daily count';$('#growthCountId').value=d.id||'';$('#growthCountDate').value=d.activity_date||'';$('#growthCustomers').value=d.customers_registered??0;$('#growthDrivers').value=d.drivers_registered??0;openModal(m)})); const add=$('#new-growth-count');if(add)add.addEventListener('click',()=>{setTimeout(()=>{$('#growthCountTitle')&&($('#growthCountTitle').textContent='Add daily count');$('#growthCountId')&&($('#growthCountId').value='');},0)}); }
  function initTaskViewer(){ $$('[data-task-view]').forEach(btn=>btn.addEventListener('click',()=>{let d={};try{d=JSON.parse(btn.dataset.taskView||'{}')}catch{};const m=$('#taskViewModal');if(!m)return;$('#taskViewCode').textContent=d.code||'Task details';$('#taskViewTitle').textContent=d.title||'Task';$('#taskViewDescription').textContent=d.description||'No description provided.';$('#taskViewAssignee').textContent=d.assignee||'Unassigned';$('#taskViewCategory').textContent=d.category||'General';$('#taskViewPriority').textContent=d.priority||'—';$('#taskViewDue').textContent=d.due||'No due date';$('#taskViewStart').textContent=d.start||'—';$('#taskViewCompleted').textContent=d.completed||'—';const st=$('#taskViewStatus');if(st){st.textContent=d.status||'—';st.className='status-chip '+(d.status_key||'')}const progress=Math.max(0,Math.min(100,Number(d.progress)||0));$('#taskViewProgressText').textContent=progress+'%';$('#taskViewProgressBar').style.width=progress+'%';openModal(m)})); }

  function chartDefaults(){ if(!window.Chart)return; Chart.defaults.font.family='Inter, system-ui, sans-serif';Chart.defaults.color='#7a879b';Chart.defaults.font.size=9;Chart.defaults.plugins.legend.labels.usePointStyle=true;Chart.defaults.plugins.legend.labels.boxWidth=7; }
  function makeCharts(){ const d=window.__IDRIVER_DASHBOARD__; if(!d||!window.Chart)return; chartDefaults(); const grid='rgba(123,139,168,.12)'; const blue='rgba(52,105,247,.9)',blueFill='rgba(52,105,247,.10)'; const reg=$('#registrationChart'); if(reg) new Chart(reg,{type:'line',data:{labels:d.daily.labels,datasets:[{data:d.daily.values,label:'Verified drivers',borderColor:blue,backgroundColor:blueFill,borderWidth:2,pointRadius:2,pointHoverRadius:4,tension:.4,fill:true}]},options:{responsive:true,maintainAspectRatio:false,interaction:{intersect:false,mode:'index'},plugins:{legend:{display:false}},scales:{x:{grid:{display:false},border:{display:false}},y:{beginAtZero:true,ticks:{precision:0},grid:{color:grid},border:{display:false}}}}}); const status=$('#statusChart'); if(status) new Chart(status,{type:'doughnut',data:{labels:d.status.labels,datasets:[{data:d.status.values,backgroundColor:['#356df7','#625ce9','#18a6c6','#f0a62d','#df5265','#41ae80','#9aa5b6'],borderWidth:0,hoverOffset:4}]},options:{responsive:true,maintainAspectRatio:false,cutout:'72%',plugins:{legend:{position:'bottom'}}}}); const pri=$('#priorityChart'); if(pri) new Chart(pri,{type:'bar',data:{labels:d.priority.labels,datasets:[{data:d.priority.values,label:'Open tasks',backgroundColor:['#79a5e7','#746fe0','#e8a43b','#df5367'],borderRadius:7,borderSkipped:false}]},options:{responsive:true,maintainAspectRatio:false,plugins:{legend:{display:false}},scales:{x:{grid:{display:false},border:{display:false}},y:{beginAtZero:true,ticks:{precision:0},grid:{color:grid},border:{display:false}}}}}); const work=$('#workloadChart'); if(work) new Chart(work,{type:'bar',data:{labels:d.workload.labels,datasets:[{data:d.workload.values,label:'Active tasks',backgroundColor:'#4c74e9',borderRadius:7,borderSkipped:false}]},options:{indexAxis:'y',responsive:true,maintainAspectRatio:false,plugins:{legend:{display:false}},scales:{x:{beginAtZero:true,ticks:{precision:0},grid:{color:grid},border:{display:false}},y:{grid:{display:false},border:{display:false}}}}}); }
  function animateText(el,value,suffix=''){ if(!el)return;const old=parseFloat((el.textContent||'0').replace(/,/g,''))||0;const start=performance.now(),dur=450;function frame(now){const p=Math.min(1,(now-start)/dur),v=old+(value-old)*(1-Math.pow(1-p,3));el.textContent=(suffix?Number(v).toFixed(1):fmt.format(Math.round(v)))+suffix;if(p<1)requestAnimationFrame(frame)}requestAnimationFrame(frame);el.closest('.metric-card,.pace-grid>div')?.classList.add('metric-flash');setTimeout(()=>el.closest('.metric-card,.pace-grid>div')?.classList.remove('metric-flash'),700); }
  async function refreshDashboard(){ if(!$('#orbitValue')||document.hidden)return;const btn=$('[data-manual-refresh]');btn?.classList.add('is-loading');try{const res=await fetch(base+'/api/dashboard-stats.php',{headers:{'Accept':'application/json','X-CSRF-TOKEN':csrf},credentials:'same-origin'});if(!res.ok)throw new Error('Refresh failed');const json=await res.json(),x=json.data,p=x.progress;animateText($('#metricTotalDrivers'),x.totalDrivers);animateText($('#metricCampaignDrivers'),p.counted);animateText($('#metricCompletion'),p.percentage,'%');animateText($('#metricDaysRemaining'),p.days_remaining);animateText($('#metricToday'),p.today_count);animateText($('#metricPending'),x.pending);animateText($('#metricOverdue'),x.overdue);animateText($('#metricCompleted'),x.completed);animateText($('#metricEmployees'),x.activeEmployees);$('#orbitCount').textContent=fmt.format(p.counted)+' / '+fmt.format(p.target);$('#orbitPercent').textContent=Number(p.percentage).toFixed(1)+'%';$('#orbitValue').style.strokeDashoffset=100-p.visual_percentage;$('#linearProgress').style.width=p.visual_percentage+'%';$('#remainingDrivers').textContent=fmt.format(p.remaining)+' drivers remaining';$('#avgDaily').textContent=Number(p.average_daily).toFixed(1);$('#requiredDaily').textContent=Number(p.required_daily).toFixed(1);$('#plannedToDate').textContent=fmt.format(Math.round(p.planned_to_date));$('#projectedDate').textContent=p.projected_completion_date?new Date(p.projected_completion_date+'T00:00:00').toLocaleDateString(undefined,{day:'2-digit',month:'short'}):'—';$('#lastSync').textContent=new Date().toLocaleTimeString();const chip=$('#paceChip');if(chip){chip.classList.toggle('on-track',p.pace_status==='on-track');chip.classList.toggle('behind',p.pace_status!=='on-track');chip.lastChild.textContent=p.pace_status==='on-track'?'On required pace':'Below required pace'}}catch(e){console.warn(e)}finally{btn?.classList.remove('is-loading')}}
  function initRealtime(){ if(!$('#orbitValue'))return; const sec=Math.max(10,Number(window.APP?.refreshSeconds)||20); setInterval(refreshDashboard,sec*1000); $('[data-manual-refresh]')?.addEventListener('click',refreshDashboard); document.addEventListener('visibilitychange',()=>{if(!document.hidden)refreshDashboard()}); }
  function openTaskCreateFromHash(){
    if(location.hash!=='#new-task')return;
    const trigger=$('#new-task'), modal=$('#taskModal');
    if(trigger){setTimeout(()=>trigger.click(),40);return;}
    if(modal)openModal(modal);
  }
  function initTaskDeepLink(){
    // Opening Add task while already on tasks.php changes only the hash. Handle it immediately.
    $$('a[href]').forEach(a=>{
      let target;try{target=new URL(a.href,location.href)}catch{return}
      if(!target.pathname.endsWith('/tasks.php')||target.hash!=='#new-task')return;
      a.dataset.taskCreateLink='1';
      a.addEventListener('click',e=>{
        const samePage=target.pathname===location.pathname;
        if(!samePage)return;
        e.preventDefault();
        if(location.hash!=='#new-task')history.pushState(null,'','#new-task');
        const trigger=$('#new-task');if(trigger)trigger.click();else openTaskCreateFromHash();
      });
    });
    window.addEventListener('hashchange',openTaskCreateFromHash);
    window.addEventListener('pageshow',()=>{if(location.hash==='#new-task')openTaskCreateFromHash()});
    openTaskCreateFromHash();
  }
  function initPageExit(){ $$('a[href]').forEach(a=>{a.addEventListener('click',e=>{if(e.defaultPrevented||e.metaKey||e.ctrlKey||a.target==='_blank'||a.href.startsWith('javascript:')||a.getAttribute('href')?.startsWith('#'))return; if(a.origin!==location.origin)return; document.body.classList.add('page-leaving');});}); }
  document.addEventListener('DOMContentLoaded',()=>{initIcons();toastAutoHide();initSidebar();initModals();initConfirm();initPassword();initTaskEditor();initTaskCreate();initTaskKanban();initTaskViewer();initGrowthEditor();makeCharts();initRealtime();initTaskDeepLink();initPageExit();});
})();
