/* eslint-disable no-empty */
import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getInit from '@salesforce/apex/WorkerAssistantController.getInit';
import reorder from '@salesforce/apex/WorkerAssistantController.reOrder';
import savedat from '@salesforce/apex/WorkerAssistantController.saveWD';
import savehours from '@salesforce/apex/WorkerAssistantController.saveWH';
import savewas from '@salesforce/apex/WorkerAssistantController.saveWAS';
import deletewa from '@salesforce/apex/WorkerAssistantController.deleteWA';
import mprogress from '@salesforce/apex/WorkerAssistantController.markProgress';
import saveWAWH from '@salesforce/apex/WorkerAssistantController.saveWAWH';
import changestats from '@salesforce/apex/WorkerAssistantController.changeStatus';
import isrunning from '@salesforce/apex/WorkerAssistantController.isRunning';
import saveFeedView from '@salesforce/apex/WorkerAssistantController.saveFeedView';
import Id from '@salesforce/user/Id';
export default class workerAssistantMain extends NavigationMixin(LightningElement) {
    @track userId = Id;
    @track curResource;
    @track hello;
    @track adtResources;
    @track shownResources = [];
    @track hasscope;
    @track activeScopes = [];
    @track shownScopes = [];
    @track dragSrcEl;
    @track isLoading;
    @track issuename;
    @track whMap;
    @track whsDescs = {};
    @track lastwhMap = {};
    @track admin;
    @track pm;
    @track wdRequired;
    @track runjob;
    @track issuetime;
    @track issuestr;
    @track totalHours;
    @track cachetotalHours;
    @track billableHours;
    @track wd = {};
    @track was = [];
    @track msg;
    @track locations = [];
    @track statuses = [];
    @track origStatuses = [];
    @track projects = [];
    @track selectedProjects = [];
    @track selectedStatuses = [];
    @track showFilters = false;
    get wdCheckOK(){
        return this.wdRequired==false||(this.wd.Id!=null);
    }
    get billablePercentage(){
        let res = 0;
        if(this.wd.Total_Hours__c!=null&&this.wd.Total_Hours__c!=0&&this.billableHours!=null){
            res = (this.billableHours/this.wd.Total_Hours__c)*100;
            res = Math.floor((res));
        }
        return res;
    }
    get billableClass(){
        return 'c100 p'+String((this.billablePercentage>100?100:this.billablePercentage))+' small '+(this.billablePercentage<80?'bad':(this.billablePercentage<94?'orange':'green'));
    }
    get noFilters(){
        return this.selectedProjects.length==0&&this.selectedStatuses.length==0;
    }
    get noFiltersProj(){
        return this.selectedProjects.length==0;
    }
    toggleFilter(){
        if(this.showFilters===true)    this.showFilters = false;
        else                           this.showFilters = true;
    }
    toggleStatus(e){
        let show = !this.selectedStatuses.includes(e.target.dataset.value);
        if(show){
            this.selectedStatuses.push(e.target.dataset.value);
        } else {
            this.selectedStatuses = this.selectedStatuses.filter(val => val !== e.target.dataset.value);
        }
        for(let i=0;i<this.statuses.length;i++){
            if(this.statuses[i].value===e.target.dataset.value){
                this.statuses[i].sel = show;
                break;
            }
        }
        this.handleFilters();
    }
    toggleProject(e){
        this.projectFilterHandler(e.target.dataset.value);
    }
    changeProject(e){
        this.projectFilterHandler(e.target.value);
    }
    projectFilterHandler(v){
        let show = !this.selectedProjects.includes(v);
        if(show){
            this.selectedProjects.push(v);
        } else {
            this.selectedProjects = this.selectedProjects.filter(val => val !== v);
        }
        for(let i=0;i<this.projects.length;i++){
            if(this.projects[i].value===v){
                this.projects[i].sel = show;
                break;
            }
        }
        this.handleFilters();
    }
    resetStatuses(){
        this.selectedStatuses = [];
        for(let i=0;i<this.statuses.length;i++){
            this.statuses[i].sel = this.origStatuses[i].sel;
            if(this.statuses[i].sel===true){
                this.selectedStatuses.push(this.statuses[i].value);
            }
        }
        this.handleFilters();
    }
    resetProjects(){
        this.selectedProjects = [];
        for(let i=0;i<this.projects.length;i++){
            this.projects[i].sel = false;
        }
        this.handleFilters();
    }
    connectedCallback(){
        this.isLoading = true;
        this.issuestr = null;
        getInit({userid: this.userId})
            .then(result => {
                result = JSON.parse(result);
                this.origStatuses = JSON.parse(JSON.stringify(result.statuses));
                if(!this.statuses||this.statuses.length==0){
                    this.statuses = result.statuses;
                    this.selectedStatuses = [];
                    for(let i=0;i<this.statuses.length;i++){
                        if(this.statuses[i].sel===true){
                            this.selectedStatuses.push(this.statuses[i].value);
                        }
                    }
                }
                this.locations = result.locations;
                this.curResource = result.curResource;
                this.totalHours = result.totalHours;
                this.billableHours = result.billableHours;
                this.wd = result.curResource.todayWD;
                this.was = result.was;
                if(!this.wd.Total_Hours__c){
                    this.showWD('1');
                }
                else{
                    this.showWD('2');
                }
                this.cachetotalHours = 0;
                this.admin = result.admin;
                this.whMap = JSON.parse(result.whMap);
                this.pm = result.pm;
                this.wdRequired = result.wdRequired;
                this.msg = result.msg;
                this.adtResources = result.adtResources;
                this.activeScopes = result.activeScopes;
                this.hello = 'Hi '+this.curResource.name + ' ';
                this.shownResources = [this.curResource];
                this.shownScopes = [];
                this.hasscope = false;
                this.curResource.numown = 0;
                if(!this.projects||this.projects.length==0){
                    this.projects = [];
                    this.selectedProjects = [];
                }
                let prjsKey = this.projects.map(a => a.value);
                for(let i=0;i<this.curResource.issues.length;i++){
                    for(let j=0;j<this.curResource.issues[i].statuses.length;j++){
                        if(this.curResource.issues[i].statuses[j].value===this.curResource.issues[i].status){
                            this.curResource.issues[i].statuses[j].sel = true;
                        }
                    }
                    this.curResource.issues[i].showit = /*((this.pm))&&*/(this.curResource.showall||this.curResource.assigned||this.curResource.issues[i].okview);
                    this.checkAddProj(this.curResource.issues[i],prjsKey);
                }
                for(let i=0;i<this.curResource.ownedissues.length;i++){
                    for(let j=0;j<this.curResource.ownedissues[i].statuses.length;j++){
                        if(this.curResource.ownedissues[i].statuses[j].value===this.curResource.ownedissues[i].status){
                            this.curResource.ownedissues[i].statuses[j].sel = true;
                        }
                    }
                    if(this.curResource.ownedissues[i].okview)   this.curResource.numown++;
                    this.checkAddProj(this.curResource.ownedissues[i],prjsKey);
                }
                for(let i=0;i<this.curResource.waitingissues.length;i++){
                    for(let j=0;j<this.curResource.waitingissues[i].statuses.length;j++){
                        if(this.curResource.waitingissues[i].statuses[j].value===this.curResource.waitingissues[i].status){
                            this.curResource.waitingissues[i].statuses[j].sel = true;
                        }
                    }
                    this.checkAddProj(this.curResource.waitingissues[i],prjsKey);
                }
                for(let i=0;i<this.adtResources.length;i++){
                    this.adtResources[i].numown = 0;
                    for(let j=0;j<this.adtResources[i].issues.length;j++){
                        for(let k=0;k<this.adtResources[i].issues[j].statuses.length;k++){
                            if(this.adtResources[i].issues[j].statuses[k].value===this.adtResources[i].issues[j].status){
                                this.adtResources[i].issues[j].statuses[k].sel = true;
                            }
                        }
                        this.adtResources[i].issues[j].showit = /*((this.pm))&&*/(this.adtResources[i].showall||this.adtResources[i].assigned||this.adtResources[i].issues[j].okview);
                        if(this.adtResources[i].okview===true){
                            this.checkAddProj(this.adtResources[i].issues[j],prjsKey);
                        }
                    }
                    for(let j=0;j<this.adtResources[i].ownedissues.length;j++){
                        for(let k=0;k<this.adtResources[i].ownedissues[j].statuses.length;k++){
                            if(this.adtResources[i].ownedissues[j].statuses[k].value===this.adtResources[i].ownedissues[j].status){
                                this.adtResources[i].ownedissues[j].statuses[k].sel = true;
                            }
                        }
                        if(this.adtResources[i].ownedissues[j].okview)   this.adtResources[i].numown++;
                        if(this.adtResources[i].okview===true){
                            this.checkAddProj(this.adtResources[i].ownedissues[j],prjsKey);
                        }
                    }
                }
                this.projects.sort((a,b) => (a.label < b.label ? -1 : (a.label > b.label ? 1 : 0)));
                this.handleFilters();
                this.loadLocal();
            })
            .catch(error => {
                const ev = new ShowToastEvent({
                    title: 'ERROR',
                    message: (error.body!=null?error.body.message:''),
                    variant: 'error',
                    mode: 'dismissable'
                });
                // eslint-disable-next-line no-console
                console.log(error);
                this.dispatchEvent(ev);
                this.isLoading = false;
            });
    }
    checkAddProj(issue,prjsKey){
        if(issue.projid&&!prjsKey.includes(issue.projid)){
            prjsKey.push(issue.projid);
            this.projects.push({label:issue.projname,value:issue.projid,sel:false});
        }
    }
    handleFilters(){
        for(let i=0;i<this.activeScopes.length;i++){
            this.activeScopes[i].isFiltered = this.isFiltered(this.activeScopes[i], true);
        }
        for(let i=0;i<this.curResource.issues.length;i++){
            this.curResource.issues[i].isFiltered = this.isFiltered(this.curResource.issues[i], false);
        }
        for(let i=0;i<this.curResource.ownedissues.length;i++){
            this.curResource.ownedissues[i].isFiltered = this.isFiltered(this.curResource.ownedissues[i], false);
        }
        for(let i=0;i<this.curResource.waitingissues.length;i++){
            this.curResource.waitingissues[i].isFiltered = this.isFiltered(this.curResource.waitingissues[i], false);
        }
        for(let i=0;i<this.adtResources.length;i++){
            let allFiltered = true;
            for(let j=0;j<this.adtResources[i].issues.length;j++){
                this.adtResources[i].issues[j].isFiltered = this.isFiltered(this.adtResources[i].issues[j], false);
                allFiltered = allFiltered&&this.adtResources[i].issues[j].isFiltered;
            }
            for(let j=0;j<this.adtResources[i].ownedissues.length;j++){
                this.adtResources[i].ownedissues[j].isFiltered = this.isFiltered(this.adtResources[i].ownedissues[j], false);
                allFiltered = allFiltered&&this.adtResources[i].ownedissues[j].isFiltered;
            }
            this.adtResources[i].isFiltered = allFiltered&&!this.noFiltersProj;
        }
    }
    isFiltered(rec, isScope){
        let filtered = false;
        if(this.selectedProjects.length>0){
            filtered = !this.selectedProjects.includes(rec.projid);
        }
        if(isScope===false&&this.selectedStatuses.length>0&&!filtered){
            filtered = !this.selectedStatuses.includes(rec.status);
        }
        return filtered;
    }
    initTime(wh){
        if(wh.worktime==null)   wh.worktime = 0;
        if(wh.starttime==null) wh.starttime = new Date();
        this.showPause(wh);
        const loc =  this;
        loc.issuetime = wh.worktime;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.runjob = setInterval(function(){
            loc.issuetime += 1;
            loc.issuestr = loc.getStrTime(loc.issuetime);
        }, 1000);
    }
    showPause(wh){
        wh.playstyle = 'hide';
        wh.boxstyle = 'blinking';
        wh.pausestyle = '';
    }
    edtWorkTime(e){
        let rec = this.fastFindRec(e.target.dataset.recid);
        if(rec.wh.worktime!=null){
            this.cachetotalHours -= (rec.wh.worktime/3600);
        }
        rec.wh.inputtime = e.target.value!=null?e.target.value:0;
        rec.wh.worktime = rec.wh.inputtime*60;
        rec.wh.runtime = this.getStrTime(rec.wh.worktime);
        this.whMap[rec.id] = rec.wh;
        this.calcCache(rec.wh);
        this.saveWHlocal();
    }
    showWD(forceShow='0'){
        let swd = this.template.querySelector('[data-wd="true"]');
        if(forceShow==='1') swd.style.display = 'flex';
        else if(forceShow==='2') swd.style.display = 'none';
        else{
            if(swd.style.display==='none') swd.style.display = 'flex';
            else swd.style.display = 'none';
        }
    }
    showWAS(){
        let swas = this.template.querySelector('[data-was="true"]');
        if(swas.style.display==='none') swas.style.display = '';
        else swas.style.display = 'none';
    }
    showEdtWH(e){
        let strt = this.template.querySelector('[data-strt="'+e.target.dataset.recid+'"]');
        if(strt.style.display==='none'){
            let rec = this.fastFindRec(e.target.dataset.recid);
            rec.wh.inputtime = rec.wh.worktime==null?0:rec.wh.worktime/60;
            rec.wh.inputtime = Math.round(rec.wh.inputtime * 100) / 100;
            strt.value = rec.wh.inputtime;
            strt.style.display = '';
        }
        else strt.style.display = 'none';
    }
    hidePause(wh){
        wh.playstyle = '';
        wh.boxstyle = '';
        wh.pausestyle = 'hide';
    }
    changeValShow(e){
        let res;
        for(let i=0;i<this.adtResources.length;i++){
            if(this.adtResources[i].id===e.target.dataset.recid){
                res = this.adtResources[i];
                break;
            }
        }
        res.showall=e.target.checked;
        for(let i=0;i<res.issues.length;i++){
            res.issues[i].showit = /*((this.pm))&&*/(res.showall||res.issues[i].okview||res.assigned);
        }
    }
    getMinute(rec){
        if(rec.wh.playstyle!==''){
            this.hidePause(rec.wh);
            if(rec.wh.starttime!=null){
                if(rec.wh.worktime==null)   rec.wh.worktime = 0;
                rec.wh.worktime += this.getDiffTime(rec.wh);
            }
            rec.wh.starttime = null;
            rec.wh.runtime = this.getStrTime(rec.wh.worktime);
            if(rec.issuemine==='true'){
                isrunning({recid:rec.id,run:false})
                    .then(() => {
                        rec.running = '';
                    })
            }
        }
    }
    getDiffTime(wh){
        return ((new Date().getTime() - new Date(wh.starttime).getTime())/1000);
    }
    getStrTime(sectime){
        if(sectime!=null){
            let sec_num = parseInt(sectime, 10); // don't forget the second param
            if(sec_num===0)  return null;
            let hours = Math.floor(sec_num / 3600);          
            let minutes = Math.floor((sec_num - (hours * 3600)) / 60);
            let seconds = sec_num - (hours * 3600) - (minutes * 60);
            if (hours   < 10) {hours   = "0"+hours;}
            if (minutes < 10) {minutes = "0"+minutes;}
            if (seconds < 10) {seconds = "0"+seconds;}
            return hours+':'+minutes+':'+seconds;
        }
        return null;
    }
    funcElse(obj){
        this.getMinute(obj);
        this.saveWHtoMap(obj);
    }
    toggleWait(e){
        if(this.curResource.waitingshow===true)  this.curResource.waitingshow = false;
        else    this.curResource.waitingshow = true;
    }
    workPlay(e){
        let edits = this.template.querySelectorAll('[data-isedt="true"]');
        for(let i=0;i<edits.length;i++)
            edits[i].style.display = 'none';
        if(this.runjob!=null){
            clearInterval(this.runjob);
        }
        let rec = this.slowFindRec(e.target.dataset.recid,true,false);
        this.issuename = rec.name;
        if(e.target.dataset.ismine==='true'){
            isrunning({recid:e.target.dataset.recid,run:true})
                .then(() => {
                    rec.running = 'blinking';
                })
        }
        this.getMinute(rec);
        this.initTime(rec.wh);
        this.saveWHtoMap(rec);
        this.saveWHlocal();
    }
    saveWHtoMap(rec){
        if((rec.wh.worktime!==0&&rec.wh.worktime!=null)||rec.wh.starttime!==null){
            this.whMap[rec.id] = rec.wh;
        }
    }
    funcAnyWay(obj){
        if(obj) this.calcCache(obj.wh);
    }
    workPause(e, direct = true){
        this.issuestr = null;
        if(this.runjob!=null){
            clearInterval(this.runjob);
        }
        this.cachetotalHours = 0;
        let rec = this.slowFindRec(e.target.dataset.recid,true,true);
        if(e.target.dataset.ismine==='true'){
            isrunning({recid:e.target.dataset.recid,run:false})
                .then(() => {
                    rec.running = '';
                })
        }
        if(direct)  this.saveWHlocal();
    }
    workStop(e){
        this.workPause(e,false);
        let steps = 0.5;
        let minwh = 0.5;
        let numwh = 0;
        let rec = this.fastFindRec(e.target.dataset.recid);
        if(rec.wh.worktime!=null){
            let tempd = parseFloat(parseFloat(rec.wh.worktime/3600).toFixed(3));
            let zerod = Math.floor((tempd.toFixed(2))*4)/4; 
            if(tempd!==zerod)
                numwh = zerod+steps;
            else
                numwh = zerod;
            if(numwh<minwh) numwh = minwh;
        }
        rec.wh.numofhours = numwh;
        if(rec.wh.worktime!=null){
            this.cachetotalHours -= (rec.wh.worktime/3600);
            this.cachetotalHours = Math.round(this.cachetotalHours* 100) / 100;
        }
        rec.wh.id = null;
        rec.wh.worktime = 0;
        rec.wh.runtime = null;
        this.whMap[e.target.dataset.recid] = rec.wh;
        this.saveWHlocal();
        try{
            let det = this.template.querySelector('[data-det="'+e.target.dataset.recid+'"]');
            det.style.display = '';
        } catch(er){}
        try{
            let dat = this.template.querySelector('[data-moredat="'+e.target.dataset.recid+'"]');
            dat.style.display = 'none';
        } catch(er){}
        try{
            let chat = this.template.querySelector('[data-chatter="'+e.target.dataset.recid+'"]');
            chat.style.display = 'none';
        } catch(er){}
        let whd = this.template.querySelector('[data-newwh="'+e.target.dataset.recid+'"]');
        whd.style.display = '';
    }
    scopChange(event){
        if(event.target.value!==''&&event.target.value!==null){
            let del = false;
            let arr = [];
            for(let i=0;i<this.shownScopes.length;i++){
                if(this.shownScopes[i].id===event.target.value){
                    del = true;
                }
                else{
                    arr.push(this.shownScopes[i].id);
                }
            }
            if(!del){
                for(let i=0;i<this.activeScopes.length;i++){
                    if(this.activeScopes[i].id===event.target.value){
                        this.shownScopes.push(this.activeScopes[i]);
                        arr.push(this.activeScopes[i].id);
                        break;
                    }
                }
            }
            this.scopcheck();
            localStorage.setItem('sfwsscopes',JSON.stringify(arr));
        }
    }
    scopcheck(){
        this.hasscope = this.shownScopes.length>0;
    }
    removeScope(event){
        if(event.target.dataset.recid!==''&&event.target.dataset.recid!==null){
            let arr = [];
            let rec;
            for(let i=0;i<this.shownScopes.length;i++){
                if(this.shownScopes[i].id===event.target.dataset.recid){
                    rec = this.shownScopes[i];
                    if((rec.wh.worktime!==null&&rec.wh.worktime!==0)||rec.wh.starttime!=null){
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error updating record',
                                message: 'Please save Cached time',
                                variant: 'error',
                            }),
                        );
                        return;
                    }
                    this.shownScopes.splice(i,1);
                }
                else{
                    arr.push(this.shownScopes[i].id);
                }
            }
            this.scopcheck();
            localStorage.setItem('sfwsscopes',JSON.stringify(arr));
        }
    }
    pickChange(event){
        if(event.target.value!==''&&event.target.value!==null){
            let del = false;
            let arr = [];
            for(let i=0;i<this.shownResources.length;i++){
                if(this.shownResources[i].id===event.target.value){
                    del = true;
                }
                else{
                    arr.push(this.shownResources[i].id);
                }
            }
            if(!del){
                for(let i=0;i<this.adtResources.length;i++){
                    if(this.adtResources[i].id===event.target.value){
                        this.shownResources.push(this.adtResources[i]);
                        arr.push(this.adtResources[i].id);
                        break;
                    }
                }
            }
            localStorage.setItem('sfwsres',JSON.stringify(arr));
        }
    }
    moveResLeft(event){
        this.moveRes(event.target.dataset.recid, true);
    }
    moveResRight(event){
        this.moveRes(event.target.dataset.recid, false);
    }
    moveRes(rid, isLeft){
        if(rid!==null&&rid!==''){
            let arr = [];
            for(let i=0;i<this.shownResources.length;i++){
                if(this.shownResources[i].id===rid){
                    if(isLeft){
                        if(i>1){
                            let temp = this.shownResources[i-1];
                            this.shownResources[i-1] = this.shownResources[i];
                            this.shownResources[i] = temp;
                        }
                    } else {
                        if(i<this.shownResources.length-1){
                            let temp = this.shownResources[i+1];
                            this.shownResources[i+1] = this.shownResources[i];
                            this.shownResources[i] = temp;
                        }
                    }
                    break;
                }
            }
            for(let i=0;i<this.shownResources.length;i++){
                arr.push(this.shownResources[i].id);
            }
            localStorage.setItem('sfwsres',JSON.stringify(arr));
        }
    }
    moveScopeLeft(event){
        this.moveScope(event.target.dataset.recid, true);
    }
    moveScopeRight(event){
        this.moveScope(event.target.dataset.recid, false);
    }
    moveScope(rid, isLeft){
        if(rid!==null&&rid!==''){
            let arr = [];
            for(let i=0;i<this.shownScopes.length;i++){
                if(this.shownScopes[i].id===rid){
                    if(isLeft){
                        if(i>0){
                            let temp = this.shownScopes[i-1];
                            this.shownScopes[i-1] = this.shownScopes[i];
                            this.shownScopes[i] = temp;
                        }
                    } else {
                        if(i<this.shownScopes.length-1){
                            let temp = this.shownScopes[i+1];
                            this.shownScopes[i+1] = this.shownScopes[i];
                            this.shownScopes[i] = temp;
                        }
                    }
                    break;
                }
            }
            for(let i=0;i<this.shownScopes.length;i++){
                arr.push(this.shownScopes[i].id);
            }
            localStorage.setItem('sfwsscopes',JSON.stringify(arr));
        }
    }
    removeRes(event){
        if(event.target.dataset.recid!==''&&event.target.dataset.recid!==null){
            let arr = [];
            let rec;
            for(let i=0;i<this.shownResources.length;i++){
                if(this.shownResources[i].id===event.target.dataset.recid){
                    for(let j=0;j<this.shownResources[i].issues.length;j++){
                        rec = this.shownResources[i].issues[j];
                        if((rec.wh.worktime!==null&&rec.wh.worktime!==0)||rec.wh.starttime!=null){
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error updating record',
                                    message: 'Please save Cached time',
                                    variant: 'error',
                                }),
                            );
                            return;
                        }
                    }
                    for(let j=0;j<this.shownResources[i].ownedissues.length;j++){
                        rec = this.shownResources[i].ownedissues[j];
                        if((rec.wh.worktime!==null&&rec.wh.worktime!==0)||rec.wh.starttime!=null){
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error updating record',
                                    message: 'Please save Cached time',
                                    variant: 'error',
                                }),
                            );
                            return;
                        }
                    }
                    for(let j=0;j<this.shownResources[i].waitingissues.length;j++){
                        rec = this.shownResources[i].waitingissues[j];
                        if((rec.wh.worktime!==null&&rec.wh.worktime!==0)||rec.wh.starttime!=null){
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error updating record',
                                    message: 'Please save Cached time',
                                    variant: 'error',
                                }),
                            );
                            return;
                        }
                    }
                    this.shownResources.splice(i,1);
                }
                else{
                    arr.push(this.shownResources[i].id);
                }
            }
            localStorage.setItem('sfwsres',JSON.stringify(arr));
        }
    }
    loadLocal(){
        let whsDescs = localStorage.getItem('sfwhsdesc');
        if(whsDescs!=null&&whsDescs!==''){
            this.whsDescs = JSON.parse(whsDescs);
        }
        let arrstr = localStorage.getItem('sfwsres');
        let usedres = [];
        if(arrstr!=null&&arrstr!==''){
            arrstr = JSON.parse(arrstr);
            for(let i=0;i<arrstr.length;i++){
                for(let j=0;j<this.adtResources.length;j++){
                    if(arrstr[i]===this.adtResources[j].id&&!usedres.includes(this.adtResources[j].id)){
                        this.shownResources.push(this.adtResources[j]);
                        usedres.push(this.adtResources[j].id);
                        break;
                    }
                }
            }
        }
        for(let j=0;j<this.adtResources.length;j++){
            if(this.adtResources[j].okview===true&&!usedres.includes(this.adtResources[j].id)){
                this.shownResources.push(this.adtResources[j]);
                usedres.push(this.adtResources[j].id);
            }
        }
        let scopstr = localStorage.getItem('sfwsscopes');
        if(scopstr!=null&&scopstr!==''){
            scopstr = JSON.parse(scopstr);
            for(let i=0;i<scopstr.length;i++){
                for(let j=0;j<this.activeScopes.length;j++){
                    if(scopstr[i]===this.activeScopes[j].id&&!usedres.includes(this.activeScopes[j].id)){
                        this.shownScopes.push(this.activeScopes[j]);
                        usedres.push(this.activeScopes[j].id);
                        break;
                    }
                }
            }
        }
        for(let i=0;i<this.activeScopes.length;i++){
            if(!usedres.includes(this.activeScopes[i].id)&&((this.activeScopes[i].wh.worktime!=null&&this.activeScopes[i].wh.worktime!==0)||this.activeScopes[i].wh.starttime!=null)){
                this.shownScopes.push(this.activeScopes[i]);
                usedres.push(this.activeScopes[i].id);
            }
        }
        this.scopcheck();
        let rec;
        //this.whMap = JSON.parse(localStorage.getItem('sfwswhs'));
        if(this.whMap==null)    this.whMap = {};
        for(let i=0;i<this.curResource.issues.length;i++){
            this.loadWH(this.curResource.issues[i]);
            if(this.whMap[this.curResource.issues[i].id]!=null){
                if(this.curResource.issues[i].wh.playstyle==null||this.curResource.issues[i].wh.playstyle==='') this.hidePause(this.curResource.issues[i].wh);
                else rec = this.curResource.issues[i];
                this.calcCache(this.curResource.issues[i].wh);
            }
        }
        for(let i=0;i<this.curResource.ownedissues.length;i++){
            this.loadWH(this.curResource.ownedissues[i]);
            if(this.whMap[this.curResource.ownedissues[i].id]!=null){
                if(this.curResource.ownedissues[i].wh.playstyle==null||this.curResource.ownedissues[i].wh.playstyle==='')  this.hidePause(this.curResource.ownedissues[i].wh);
                else rec = this.curResource.ownedissues[i];
                this.calcCache(this.curResource.ownedissues[i].wh);
            }
        }
        for(let i=0;i<this.curResource.waitingissues.length;i++){
            this.loadWH(this.curResource.waitingissues[i]);
            if(this.whMap[this.curResource.waitingissues[i].id]!=null){
                if(this.curResource.waitingissues[i].wh.playstyle==null||this.curResource.waitingissues[i].wh.playstyle==='')  this.hidePause(this.curResource.waitingissues[i].wh);
                else rec = this.curResource.waitingissues[i];
                this.calcCache(this.curResource.waitingissues[i].wh);
            }
        }
        for(let i=0;i<this.adtResources.length;i++){
            for(let j=0;j<this.adtResources[i].issues.length;j++){
                this.loadWH(this.adtResources[i].issues[j]);
                if(this.whMap[this.adtResources[i].issues[j].id]!=null){
                    if(this.adtResources[i].issues[j].wh.playstyle==null||this.adtResources[i].issues[j].wh.playstyle==='')  this.hidePause(this.adtResources[i].issues[j].wh);
                    else rec = this.adtResources[i].issues[j];
                    this.calcCache(this.adtResources[i].issues[j].wh);
                }
            }
            for(let j=0;j<this.adtResources[i].ownedissues.length;j++){
                this.loadWH(this.adtResources[i].ownedissues[j]);
                if(this.whMap[this.adtResources[i].ownedissues[j].id]!=null){
                    if(this.adtResources[i].ownedissues[j].wh.playstyle==null||this.adtResources[i].ownedissues[j].wh.playstyle==='')  this.hidePause(this.adtResources[i].ownedissues[j].wh);
                    else rec = this.adtResources[i].ownedissues[j];
                    this.calcCache(this.adtResources[i].ownedissues[j].wh);
                }
            }
        }
        for(let i=0;i<this.activeScopes.length;i++){
            this.loadWH(this.activeScopes[i]);
            if(this.whMap[this.activeScopes[i].id]!=null){
                if(this.activeScopes[i].wh.playstyle==null||this.activeScopes[i].wh.playstyle==='')  this.hidePause(this.activeScopes[i].wh);
                else rec = this.activeScopes[i];
                this.calcCache(this.activeScopes[i].wh);
            }
        }
        if(rec!=null){
            this.showPause(rec.wh);
            if(rec.wh.worktime==null)   rec.wh.worktime = 0;
            const loc =  this;
            loc.issuename = rec.name;
            loc.issuetime = rec.wh.worktime + loc.getDiffTime(rec.wh);
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            this.runjob = setInterval(function(){
                loc.issuetime += 1;
                loc.issuestr = loc.getStrTime(loc.issuetime);
            }, 1000);
        }
        this.isLoading = false;
    }
    loadWH(rec){
        if(this.whMap[rec.id]!=null){
            rec.wh = this.whMap[rec.id];
            rec.wh.notbill = false;
            rec.wh.curdate = this.getDateStr();
        }
        if(this.lastwhMap[rec.id]!=null){
            let tempwh = this.lastwhMap[rec.id];
            rec.wh.curdate = tempwh.curdate;
            rec.wh.curtext = tempwh.curtext;
            rec.wh.numofhours = tempwh.numofhours;
            rec.wh.notbill = tempwh.notbill;
            this.whMap[rec.id] = rec.wh;
        }
        rec.wh.runtime = this.getStrTime(rec.wh.worktime);
        if(this.whsDescs[rec.id]!=null){
            rec.wh.curtext = this.whsDescs[rec.id];
        }
    }
    calcCache(wh){
        if(wh){
            if(wh.worktime!=null){
                this.cachetotalHours += (wh.worktime/3600);
                this.cachetotalHours = Math.round(this.cachetotalHours* 100) / 100;
            }
        }
    }
    getDateStr(){
        var d = new Date();
        return d.getFullYear()+'-'+(d.getMonth()+1)+'-'+d.getDate();
    }
    handleDragStart(e) {
        e.target.classList.add('shade');
        // eslint-disable-next-line @lwc/lwc/no-inner-html
        this.dragSrcEl = e.target;
        e.dataTransfer.effectAllowed = 'move';
        // eslint-disable-next-line @lwc/lwc/no-inner-html
        e.dataTransfer.setData('text/html', e.target.innerHTML);
    }
    handleDragOver(e) {
        if (e.preventDefault) {
          e.preventDefault(); // Necessary. Allows us to drop.
        }
        e.dataTransfer.dropEffect = 'move';  // See the section on the DataTransfer object.
        return false;
    }
    handleDragEnter(e) {
        // this / e.target is the current hover target.
        e.target.classList.add('over');
        e.target.classList.add('shade');
    }
    handleDragLeave(e) {
        e.target.classList.remove('over');  // this / e.target is previous target element.
        e.target.classList.remove('shade');  // this / e.target is previous target element.
    }
    handleDrop(e) {
        // this / e.target is current target element.
        if (e.stopPropagation) {
            e.stopPropagation(); // Stops some browsers from redirecting.
        }
        this.dragSrcEl.classList.remove('over');
        this.dragSrcEl.classList.remove('shade');
        e.target.classList.remove('over');
        e.target.classList.remove('shade');
        if (this.admin&&this.dragSrcEl.dataset.bottom!=='true'&&e.target.dataset.parent!=null&&e.target.dataset.pos!=null){
            this.isLoading = true;
            let rec = this.fastFindRec(this.dragSrcEl.dataset.recid);
            if(((rec.wh.worktime!==null&&rec.wh.worktime!==0)||rec.wh.starttime!=null)&&e.target.dataset.parent!==this.dragSrcEl.dataset.parent){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating record',
                        message: 'Please save Cached time',
                        variant: 'error',
                    }),
                );
                this.isLoading = false;
                return false;
            }
            // eslint-disable-next-line radix
            reorder({userid: e.target.dataset.parent,recid: this.dragSrcEl.dataset.recid,pos: parseInt(e.target.dataset.pos)})
                .then(() => {
                    this.refData();
                })
                .catch(error => {
                    const ev = new ShowToastEvent({
                        title: 'ERROR',
                        message: (error.body!=null?error.body.message:''),
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    // eslint-disable-next-line no-console
                    console.log(error);
                    this.dispatchEvent(ev);
                    this.isLoading = false;
                });
        }
        return false;
    }
    newWin(e){
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: e.target.dataset.recid,
                actionName: 'view',
            },
        }).then(url => {
            window.open(url);
        });
    }
    moreDat(e){
        let dat = this.template.querySelector('[data-moredat="'+e.target.dataset.more+'"]');
        if(dat.style.display === 'none')    {
            dat.style.display = '';
        }
        else    dat.style.display = 'none';
    }
    showChatter(e){
        let iframechat = this.template.querySelector('[data-chatterload="'+e.target.dataset.chat+'"]');
        let chat = this.template.querySelector('[data-chatter="'+e.target.dataset.chat+'"]');
        if(chat.style.display === 'none')    {
            iframechat.src = chat.dataset.url;
            chat.style.display = '';
        } else {
            chat.style.display = 'none';
        }
        let rec =this.fastFindRec(e.target.dataset.chat);
        rec.chatterNotify = false;
        saveFeedView({issueid:e.target.dataset.chat})
    }
    toggleView(e){
        let det = this.template.querySelector('[data-det="'+e.target.dataset.recid+'"]');
        if(det.style.display === 'none')    det.style.display = '';
        else    det.style.display = 'none';
    }
    changeValScope(e){
        let wh;
        for(let i=0;i<this.activeScopes.length;i++){
            if(this.activeScopes[i].id===e.target.dataset.recid){
                wh = this.activeScopes[i].wh;
                break;
            }
        }
        if(e.target.name==='notbill')    wh[e.target.name] = e.target.checked;
        else    wh[e.target.name] = e.target.value;
        this.whMap[e.target.dataset.recid] = wh;
        if(e.target.name==='curtext'){
            this.whsDescs[e.target.dataset.recid] = wh.curtext;
            this.saveLocalDesc();
        }
    }
    saveLocalDesc(){
        localStorage.setItem('sfwhsdesc',JSON.stringify(this.whsDescs));
    }
    changeValDat(e){
        this.wd[e.target.name] = e.target.value;
    }
    changeWA(e){
        for(let i=0;i<this.was.length;i++){
            if(this.was[i].id==e.target.dataset.recid){
                if(e.target.name=='num')
                    this.was[i].num = e.target.value;
                else if(e.target.name=='notbill')
                    this.was[i].notbill = e.target.checked;
                else
                    this.was[i].description = e.target.value;
                break;
            }
        }
    }
    saveWAS(){
        this.isLoading = true;
        savewas({wsstr:JSON.stringify(this.was)}).then(()=>{this.refData();}).catch(()=>{this.isLoading = false;});
    }
    deleteWA(e){
        this.isLoading = true;
        deletewa({recid:e.target.dataset.recid}).then(()=>{this.refData();}).catch(()=>{this.isLoading = false;});
    }
    saveWD(){
        this.isLoading = true;
        savedat({ wdstr: JSON.stringify(this.wd) }).then(() => { this.refData(); }).catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error Saving Working Day',
                    message: (error.body!=null?error.body.message:''),
                    variant: 'error'
                })
            );
            this.isLoading = false;
        });
    }
    changeVal(e){
        let rec =this.fastFindRec(e.target.dataset.recid);
        if(e.target.name==='notbill')    rec.wh[e.target.name] = e.target.checked;
        else    rec.wh[e.target.name] = e.target.value;
        this.whMap[e.target.dataset.recid] = rec.wh;
        if(e.target.name==='curtext'){
            this.whsDescs[e.target.dataset.recid] = rec.wh.curtext;
            this.saveLocalDesc();
        }
    }
    saveWHlocal(){
        saveWAWH({wawhstr: JSON.stringify(this.whMap)});
    }
    newWH(e){
        let wh = this.template.querySelector('[data-newwh="'+e.target.dataset.wh+'"]');
        if(wh.style.display === 'none')    wh.style.display = '';
        else    wh.style.display = 'none';
    }
    saveWH(e){
        this.isLoading = true;
        const recid = e.target.dataset.recid!=null?e.target.dataset.recid:e.target.dataset.scope;
        let form = this.template.querySelector('[data-formid="'+recid+'"]');
        if(!form.checkValidity()){
            this.isLoading = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Required Fields missing',
                    message: '',
                    variant: 'error',
                }),
            );
            return;
        }
        if(e.target.dataset.status==='New'){
            mprogress({recid:e.target.dataset.recid});
        }
        let rec =this.fastFindRec(recid);
        let wh = {};
        wh.Issue__c = e.target.dataset.recid;
        wh.Account__c = e.target.dataset.account;
        wh.Project__c = e.target.dataset.project;
        wh.Scope_Item__c = e.target.dataset.scope;
        wh.Performed_By_2__c = this.curResource.conid;
        wh.Date__c = rec.wh.curdate;
        wh.Billing_Date__c = rec.wh.curdate;
        wh.Number_Of_Hours__c = rec.wh.numofhours;
        wh.Description_Of_Work__c = rec.wh.curtext;
        //let recordInput = { apiName: WH_OBJECT.objectApiName, fields };
        let whd = this.template.querySelector('[data-newwh="'+recid+'"]');
        let isnotbill = rec.wh.notbill===true;
        savehours({whstr:JSON.stringify(wh)})
            .then(record=>{
                delete this.whMap[recid];
                delete this.whsDescs[recid];
                this.saveLocalDesc();
                try{
                    whd.style.display = 'none';
                }   catch(e2){
                    // eslint-disable-next-line no-console
                    console.log(e2);
                }
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Working Hour created',
                        variant: 'success',
                    }),
                );
                if(isnotbill){
                    wh.Id = record.Id;
                    wh.Billable_Hours__c = 0;
                    savehours({whstr:JSON.stringify(wh)}).then(()=>{
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'Working Hour updated as Not Billable',
                                variant: 'success',
                            }),
                        );
                        this.refData();
                    })
                    .catch(error => {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error Updating Working Hour as Not Billable',
                                message: (error.body!=null?error.body.message:''),
                                variant: 'error'
                            })
                        );
                        // eslint-disable-next-line no-console
                        console.log(error);
                        this.isLoading = false;
                    });
                }
                else{
                    this.refData();
                }
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating record',
                        message: (error.body!=null?error.body.message:''),
                        variant: 'error',
                    }),
                );
                // eslint-disable-next-line no-console
                console.log(error);
                this.isLoading = false;
            });
    }
    newIssue(e) {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/flow/New_Issue?recordId='+e.target.dataset.rid+'&retURL=/lightning/n/Worker_Assistant'
            }
        });
    }
    editIssue(e){
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                recordId: e.target.dataset.recid,
                objectApiName: 'Issue__c',
                actionName: 'edit'                
            },
            state : {
                nooverride: '1',
            }
        });
    }
    fastFindRec(rid){
        let rec;
        for(let j=0;j<this.curResource.issues.length;j++){
            if(this.curResource.issues[j].id===rid){
                rec = this.curResource.issues[j];
                break;
            }
        }
        if(rec==null){
            for(let j=0;j<this.curResource.ownedissues.length;j++){
                if(this.curResource.ownedissues[j].id===rid){
                    rec = this.curResource.ownedissues[j];
                    break;
                }
            }
        }
        if(rec==null){
            for(let j=0;j<this.curResource.waitingissues.length;j++){
                if(this.curResource.waitingissues[j].id===rid){
                    rec = this.curResource.waitingissues[j];
                    break;
                }
            }
        }
        if(rec==null){
            for(let i=0;i<this.adtResources.length;i++){
                if(rec==null){
                    for(let j=0;j<this.adtResources[i].issues.length;j++){
                        if(this.adtResources[i].issues[j].id===rid){
                            rec = this.adtResources[i].issues[j];
                            break;
                        }
                    }
                }
                if(rec==null){
                    for(let j=0;j<this.adtResources[i].ownedissues.length;j++){
                        if(this.adtResources[i].ownedissues[j].id===rid){
                            rec = this.adtResources[i].ownedissues[j];
                            break;
                        }
                    }
                }
            }
        }
        if(rec==null){
            for(let i=0;i<this.activeScopes.length;i++){
                if(this.activeScopes[i].id===rid){
                    rec = this.activeScopes[i];
                    break;
                }
            }
        }
        return rec;
    }
    slowFindRec(rid,funcelse,funcanyway){
        let rec;
        //fix for this
        for(let j=0;j<this.curResource.issues.length;j++){
            if(this.curResource.issues[j].id===rid){
                rec = this.curResource.issues[j];
                if(funcanyway&&funcelse)  this.funcElse(rec);
            }
            else if(funcelse&&!funcanyway)   this.funcElse(this.curResource.issues[j]);
            if(funcanyway)  this.funcAnyWay(this.curResource.issues[j]);
        }
        for(let j=0;j<this.curResource.ownedissues.length;j++){
            if(this.curResource.ownedissues[j].id===rid){
                rec = this.curResource.ownedissues[j];
                if(funcanyway&&funcelse)  this.funcElse(rec);
            }
            else if(funcelse&&!funcanyway)   this.funcElse(this.curResource.ownedissues[j]);
            if(funcanyway)  this.funcAnyWay(this.curResource.ownedissues[j]);
        }
        for(let j=0;j<this.curResource.waitingissues.length;j++){
            if(this.curResource.waitingissues[j].id===rid){
                rec = this.curResource.waitingissues[j];
                if(funcanyway&&funcelse)  this.funcElse(rec);
            }
            else if(funcelse&&!funcanyway)   this.funcElse(this.curResource.waitingissues[j]);
            if(funcanyway)  this.funcAnyWay(this.curResource.waitingissues[j]);
        }
        for(let i=0;i<this.adtResources.length;i++){
            for(let j=0;j<this.adtResources[i].issues.length;j++){
                if(this.adtResources[i].issues[j].id===rid){
                    rec = this.adtResources[i].issues[j];
                    if(funcanyway&&funcelse)  this.funcElse(rec);
                }
                else if(funcelse&&!funcanyway)   this.funcElse(this.adtResources[i].issues[j]);
                if(funcanyway)  this.funcAnyWay(this.adtResources[i].issues[j]);
            }                
            for(let j=0;j<this.adtResources[i].ownedissues.length;j++){
                if(this.adtResources[i].ownedissues[j].id===rid){
                    rec = this.adtResources[i].ownedissues[j];
                    if(funcanyway&&funcelse)  this.funcElse(rec);
                }
                else if(funcelse&&!funcanyway)   this.funcElse(this.adtResources[i].ownedissues[j]);
                if(funcanyway)  this.funcAnyWay(this.adtResources[i].ownedissues[j]);
            }
        }
        for(let i=0;i<this.activeScopes.length;i++){
            if(this.activeScopes[i].id===rid){
                rec = this.activeScopes[i];
                if(funcanyway&&funcelse)  this.funcElse(rec);
            }
            else if(funcelse&&!funcanyway)   this.funcElse(this.activeScopes[i]);
            if(funcanyway)  this.funcAnyWay(this.activeScopes[i]);
        }
        return rec;
    }
    changeStats(e){
        let devest = this.template.querySelector('[data-devest="'+e.target.dataset.recid+'"]');
        let devestval = null;
        if(devest){
            if(devest.value!=null&&devest.value!='')    devestval = devest.value;
        }
        this.isLoading = true;
        let rec = this.fastFindRec(e.target.dataset.recid);
        if((rec.wh.worktime!==null&&rec.wh.worktime!==0)||rec.wh.starttime!=null){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error updating record',
                    message: 'Please save Cached time',
                    variant: 'error',
                }),
            );
            e.target.value = rec.status;
            this.isLoading = false;
            return;
        }
        if(rec.status==='Draft'||rec.status==='New - Portal'){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error updating record',
                    message: 'Move this status by using the edit record icon new the "info" below',
                    variant: 'error',
                }),
            );
            e.target.value = rec.status;
            this.isLoading = false;
            return;
        }
        const target = e.target;
        changestats({recid:e.target.dataset.recid,status:e.target.value, devest: devestval})
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Issue updated',
                    variant: 'success',
                }),
            );
            this.refData();
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error updating record',
                    message: (error.body!=null?error.body.message:''),
                    variant: 'error',
                }),
            );
            target.value = rec.status;
            // eslint-disable-next-line no-console
            console.log(error);
            this.isLoading = false;
        });
    }
    refData(){
        if(this.runjob!=null){
            clearInterval(this.runjob);
        }
        this.lastwhMap = this.whMap;
        this.connectedCallback();
    }
}