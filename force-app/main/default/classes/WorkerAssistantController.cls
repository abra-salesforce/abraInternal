public without sharing class WorkerAssistantController {
    public class pageData{
        @AuraEnabled public list <status> locations;
        @AuraEnabled public list <status> statuses;
        @AuraEnabled public resource curResource;
        @AuraEnabled public Boolean admin;
        @AuraEnabled public Decimal totalHours;
        @AuraEnabled public Decimal billableHours;
        @AuraEnabled public Boolean pm;
        @AuraEnabled public Boolean user;
        @AuraEnabled public String msg;
        @AuraEnabled public List <resource> adtResources;
        @AuraEnabled public List <scope> activeScopes;
        @AuraEnabled public List <wa> was;
        @AuraEnabled public String whMap;
        @AuraEnabled public Boolean wdRequired;
        public pageData(){
            adtResources = new List <resource>();
            activeScopes = new List <scope>();
            was = new List <wa>();
        }
    }
    public class wa{
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String projid;
        @AuraEnabled public String projname;
        @AuraEnabled public String scopeid;
        @AuraEnabled public String scopename;
        @AuraEnabled public String issid;
        @AuraEnabled public String issname;
        @AuraEnabled public String description;
        @AuraEnabled public Decimal num;
        @AuraEnabled public Boolean notbill;
        public wa(Working_Hours__c w){
            id = w.id;
            name = w.name;
            projid = w.Project__c;
            projname = w.Project__r.Name;
            scopeid = w.Scope_Item__c;
            scopename = w.Scope_Item__r.Name;
            issid = w.Issue__c;
            issname = w.Issue__r.Name;
            description = w.Description_of_Work__c;
            num = w.Number_Of_Hours__c;
            notbill = w.Billable_Hours__c==0;
        }
    }
    public class scope{
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String zvname;
        @AuraEnabled public String budgetstatus;
        @AuraEnabled public String accid;
        @AuraEnabled public String accname;
        @AuraEnabled public String projid;
        @AuraEnabled public String projname;
        @AuraEnabled public Decimal billhours;
        @AuraEnabled public Decimal budget;
        @AuraEnabled public Date startDate;
        @AuraEnabled public Date endDate;
        @AuraEnabled public wh wh;
        @AuraEnabled public Boolean sel;
        public scope(Scope_Item__c scop, String empType){
            id = scop.id;
            name = scop.name;
            zvname = scop.ZV_Name__c;
            startDate = scop.Start_Date__c;
            endDate = scop.End_Date__c;
            accid = scop.Project__r.Account__c;
            accname = scop.Project__r.Account__r.Name;
            projid = scop.Project__c;
            projname = scop.Project__r.Name;
            if(empType=='Developer'){
                budget = scop.Total_Dev_Budget__c;
                billhours = scop.Total_Dev_Working_Billable_Hours__c;
            } else if(empType=='Implementation Specialist'){
                budget = scop.Total_implementation_Budget__c;
                billhours = scop.Total_Imp_Working_Billable_Hours__c;
            } else if(empType=='Project Manager'||empType=='Pardot Project Manager'){
                budget = scop.Total_PM_Budget__c;
                billhours = scop.Total_PM_Working_Billable_Hours__c;
            } else if(empType=='System Architect'){
                budget = scop.Total_Architect_Budget__c;
                billhours = scop.Total_Arc_Working_Billable_Hours__c;
            } else if(empType=='QA'){
                budget = scop.Total_QA_Budget__c;
                billhours = scop.Total_QA_Working_Billable_Hours__c;
            }
            if(budget==null) budget = 0;
            if(billhours==null) billhours = 0;
            budgetstatus = ' (' + String.valueOf(Math.round(billhours)) + '/' + String.valueOf(Math.round(budget)) + ')';
            wh = new wh();
            sel = false;
        }
    }
    public class resource{
        @AuraEnabled public String id;
        @AuraEnabled public String conid;
        @AuraEnabled public String empType;
        @AuraEnabled public String name;
        @AuraEnabled public Boolean sel;
        @AuraEnabled public Boolean main;
        @AuraEnabled public Boolean assigned;
        @AuraEnabled public Boolean okview;
        @AuraEnabled public Boolean showall;
        @AuraEnabled public Boolean isOffline;
        @AuraEnabled public String hoursOfWork;
        @AuraEnabled public Decimal numiss;
        @AuraEnabled public Decimal numown;
        @AuraEnabled public Decimal numwait;
        @AuraEnabled public Working_Days__c todayWD;
        @AuraEnabled public list <issue> issues;
        @AuraEnabled public list <issue> ownedissues;
        @AuraEnabled public list <issue> waitingissues;
        @AuraEnabled public Boolean waitingshow;
        @AuraEnabled public String rescolclass;
        public resource(User us, List <status> sts,Boolean admin,Boolean pm, List <Issue__c> usissues,String userid, Map<String,Issue__Feed> feedByIssue, List <Weekly_Hours__c> wkls, List <field> adtfields){
            id = us.id;
            name = us.Name;
            sel = false;
            okview = false;
            isOffline = false;
            showall = admin?true:false;
            assigned = us.id==UserInfo.getUserId();
            issues = new List <issue>();
            ownedissues = new List <issue>();
            waitingissues = new List <issue>();
            waitingshow = false;
            for(Issue__c is:usissues) 
                if(WorkerAssistantController.issueCheck(us.id,is.Issue_Status__c,is.Project__r.QA_User__c))   issues.add(new issue(is,sts,admin,pm,feedByIssue.get(is.id),adtfields));
                else if(!WorkerAssistantController.closedissues.contains(is.Issue_Status__c)&&is.Ownerid==userid)   ownedissues.add(new issue(is,sts,admin,pm,feedByIssue.get(is.id),adtfields));
                else if(!WorkerAssistantController.closedissues.contains(is.Issue_Status__c)&&is.Assigned_To__c==userid)    waitingissues.add(new issue(is,sts,admin,pm,feedByIssue.get(is.id),adtfields));
            main = ownedissues.size()>0?true:false;
            rescolclass = 'resource minwidth toppad';
            hoursOfWork = '';
            Integer count = 0;
            for(Weekly_Hours__c wkl:wkls){
                hoursOfWork += (count==0?'This':'\nNext')+' week: \n';
                hoursOfWork += 'Sunday: ';
                if(wkl.Sunday_actual_hours__c>0&&wkl.Sunday_start_time__c!=null&&wkl.Sunday_end_time__c!=null){
                    hoursOfWork += rmTime(wkl.Sunday_start_time__c,wkl.Sunday_end_time__c,wkl.Sunday_actual_hours__c) + '\n';
                } else {
                    hoursOfWork += + 'Off\n';
                }
                hoursOfWork += 'Monday: ';
                if(wkl.Monday_actual_hours__c>0&&wkl.Monday_start_time__c!=null&&wkl.Monday_end_time__c!=null){
                    hoursOfWork += rmTime(wkl.Monday_start_time__c,wkl.Monday_end_time__c,wkl.Monday_actual_hours__c) + '\n';
                } else {
                    hoursOfWork += + 'Off\n';
                }
                hoursOfWork += 'Tuesday: ';
                if(wkl.Tuesday_actual_hours__c>0&&wkl.Tuesday_start_time__c!=null&&wkl.Tuesday_end_time__c!=null){
                    hoursOfWork += rmTime(wkl.Tuesday_start_time__c,wkl.Tuesday_end_time__c,wkl.Tuesday_actual_hours__c) + '\n';
                } else {
                    hoursOfWork += + 'Off\n';
                }
                hoursOfWork += 'Wednesday: ';
                if(wkl.Wednesday_actual_hours__c>0&&wkl.Wednesday_start_time__c!=null&&wkl.Wednesday_end_time__c!=null){
                    hoursOfWork += rmTime(wkl.Wednesday_start_time__c,wkl.Wednesday_end_time__c,wkl.Wednesday_actual_hours__c) + '\n';
                } else {
                    hoursOfWork += + 'Off\n';
                }
                hoursOfWork += 'Thursday: ';
                if(wkl.Thursday_actual_hours__c>0&&wkl.Thursday_start_time__c!=null&&wkl.Thursday_end_time__c!=null){
                    hoursOfWork += rmTime(wkl.Thursday_start_time__c,wkl.Thursday_end_time__c,wkl.Thursday_actual_hours__c) + '\n';
                } else {
                    hoursOfWork += + 'Off\n';
                }
                hoursOfWork += 'Friday: ';
                if(wkl.Friday_actual_hours__c>0&&wkl.Friday_start_time__c!=null&&wkl.Friday_end_time__c!=null){
                    hoursOfWork += rmTime(wkl.Friday_start_time__c,wkl.Friday_end_time__c,wkl.Friday_actual_hours__c) + '\n';
                } else {
                    hoursOfWork += + 'Off\n';
                }
                count++;
            }
        }
        public string rmTime(Time t, Time t2, Decimal actualTime){
            Integer hoursDiff = (t2.hour() - t.hour());
            Integer minutesDiff = (t2.minute() - t.minute());
            Decimal timeDiff = hoursDiff+(minutesDiff/60.0);
            if(actualTime<timeDiff){
                Integer actualHours = Integer.valueof(Math.floor(actualTime));
                Integer actualMinutes = Integer.valueof((actualTime - actualHours)*60);
                t2 = t.addHours(actualHours);
                t2 = t2.addMinutes(actualMinutes);
            }
            return String.valueof(t).replace(':00.000Z','') + ' - ' + String.valueof(t2).replace(':00.000Z','');
        }
    }
    public class field{
        @AuraEnabled public Object value;
        @AuraEnabled public String api;
        @AuraEnabled public String label;
        @AuraEnabled public String key;
        public field(String a,String l){
            api = a;
            label = l;
        }
        public field(String a,String l, Object v, String id){
            api = a;
            label = l;
            value = v;
            key = id+';'+api;
        }
    }
    public class issue{
        @AuraEnabled public String id;
        @AuraEnabled public String url;
        @AuraEnabled public String name;
        @AuraEnabled public Date dat;
        @AuraEnabled public Date stdat;
        @AuraEnabled public string running;
        @AuraEnabled public Decimal queue;
        @AuraEnabled public String ownername;
        @AuraEnabled public String textname;
        @AuraEnabled public String accid;
        @AuraEnabled public String accname;
        @AuraEnabled public String relid;
        @AuraEnabled public String relname;
        @AuraEnabled public String projid;
        @AuraEnabled public String projname;
        @AuraEnabled public String scopeid;
        @AuraEnabled public String scopename;
        @AuraEnabled public String parentid;
        @AuraEnabled public String parentname;
        @AuraEnabled public String status;
        @AuraEnabled public String delivery;
        @AuraEnabled public String logid;
        @AuraEnabled public String logname;
        @AuraEnabled public String logurl;
        @AuraEnabled public String deplogid;
        @AuraEnabled public String deplogname;
        @AuraEnabled public String deplogurl;
        @AuraEnabled public String uatlogid;
        @AuraEnabled public String uatlogname;
        @AuraEnabled public String uatlogurl;
        @AuraEnabled public Decimal budget;
        @AuraEnabled public Decimal workingdays;
        @AuraEnabled public Decimal hoursperday;
        @AuraEnabled public Decimal billable;
        @AuraEnabled public Decimal totalhrs;
        @AuraEnabled public Decimal devest;
        @AuraEnabled public string colclass;
        @AuraEnabled public String prior;
        @AuraEnabled public Datetime lastChatterView;
        @AuraEnabled public Datetime lastChatterPost;
        @AuraEnabled public Boolean chatterNotify;
        @AuraEnabled public String assigned;
        @AuraEnabled public List <status> statuses;
        @AuraEnabled public wh wh;
        @AuraEnabled public Boolean isest;
        @AuraEnabled public Boolean hasest;
        @AuraEnabled public Boolean hasdelivery;
        @AuraEnabled public Boolean hasprodlog;
        @AuraEnabled public Boolean okview;
        @AuraEnabled public String issuemine;
        @AuraEnabled public Boolean isbug;
        @AuraEnabled public Boolean issueminebol;
        @AuraEnabled public List<field> adtfields;
        @AuraEnabled public Boolean noTimer;
        public issue(Issue__c is, List <status> sts,Boolean admin,Boolean pm, Issue__Feed isf, List<field> afs){
            id = is.id;
            noTimer = ((is.Issue_Status__c=='Draft'||is.Issue_Status__c=='new - Portal')&&(is.Scope_Item__c==null));
            url = '/apex/CustomChatter?id='+is.id;
            isbug = is.RecordType.Name!=null&&is.RecordType.Name.contains('Bug');
            name = is.Name;
            dat = is.Due_Date__c;
            stdat = is.Start_Date__c;
            running = is.Running__c?'blinking':'';
            ownername = is.Owner.Name;
            queue = is.Queue__c;
            textname = is.Issue_Name__c;
            accid = is.Account_Name__c;
            accname = is.Account_Name__r.name;
            relid = is.Release__c;
            relname = is.Release__r.name;
            projid = is.Project__c;
            projname = is.Project__r.name;
            scopeid = is.Scope_Item__c;
            scopename = is.Scope_Item__r.Name;
            parentid = is.Parent_Issue__c;
            parentname = is.Parent_Issue__r.Name;
            status = is.Issue_Status__c;
            isest = status=='Estimation';
            delivery = is.Delivery_Type__c;
            hasdelivery = delivery!=null;
            devest = is.Dev_Estimation__c;
            hasest = devest!=null&&devest!=0?true:false;
            logid = is.Login_Details_1__c;
            logname = is.Login_Details_1__r.Name+(is.Login_Details_1__r.System_Name__c!=null?' ('+is.Login_Details_1__r.System_Name__c+')':'');
            logurl = is.Login_URL__c;
            deplogid = is.Deploy_Login_Details__c;
            deplogname = is.Deploy_Login_Details__r.Name+(is.Deploy_Login_Details__r.System_Name__c!=null?' ('+is.Deploy_Login_Details__r.System_Name__c+')':'');
            deplogurl = is.Deploy_Login_Details_URL__c;
            uatlogid = is.UAT_Login_Details__c;
            uatlogname = is.UAT_Login_Details__r.Name+(is.UAT_Login_Details__r.System_Name__c!=null?' ('+is.UAT_Login_Details__r.System_Name__c+')':'');
            uatlogurl = is.UAT_Login_URL__c;
            budget = is.Budget__c;
            workingdays = is.Working_Days__c;
            hoursperday = workingdays!=null&&budget!=null&&workingdays!=0?(budget/workingdays).setScale(1):0;
            billable = is.Total_Billable_Hours__c;
            totalhrs = is.Total_Hours__c;
            prior = is.Customer_Priority__c;
            assigned = is.Assigned_To__r.Name;
            issueminebol = (is.Assigned_To__c == UserInfo.getUserId()&&!(WorkerAssistantController.qaissues.contains(status)&&is.Project__r.QA_User__c!=null&&is.Project__r.QA_User__c!=UserInfo.getUserId()));
            okview = (is.Ownerid == UserInfo.getUserId() || issueminebol);
            issuemine = (issueminebol?'true':'false');
            colclass = 'column '+(pm?'minwidth':'maxwidth')+(admin?'':' nondrag')+' box '+(prior==null||prior=='Medium'?'white':(prior=='Very Urgent'?'red':(prior=='High'?'yellow':'blue')));
            if(status=='Resource Monitoring')    colclass+=' monitor';
            wh = new wh();
            wh.scopeid = scopeid;
            statuses = sts;
            if(isf.id!=null)    lastChatterPost = isf.LastModifiedDate;
            if(lastChatterPost==null)   chatterNotify = false;
            else chatterNotify = true;
            adtfields = new List<field>();
            for(field f: afs){
                adtfields.add(new field(f.api,f.label,is.get(f.api),is.id));
            }
        }
    }
    public class status{
        @AuraEnabled public String value;
        @AuraEnabled public String label;
        @AuraEnabled public Boolean sel;
        public status(String val,String lab){
            value = val;
            label = lab;
            sel = false;
        }
    }
    public class wh{
        @AuraEnabled public String id;
        @AuraEnabled public Date curdate;
        @AuraEnabled public DateTime starttime;
        @AuraEnabled public Decimal worktime;
        @AuraEnabled public String runtime;
        @AuraEnabled public String playstyle;
        @AuraEnabled public String pausestyle;
        @AuraEnabled public String boxstyle;
        @AuraEnabled public String scopeid;
        @AuraEnabled public Decimal numofhours;
        @AuraEnabled public String curtext;
        @AuraEnabled public Boolean notbill;
        public wh(){
            curdate = System.Today();
            numofhours = 0;
            playstyle = '';
            pausestyle = 'hide';
            boxstyle = '';
            notbill = false;
        }
        public wh(WA_Working_Hour__c wawh){
            id = wawh.id;
            curdate = System.Today();
            numofhours = 0;
            playstyle = '';
            pausestyle = 'hide';
            boxstyle = '';
            notbill = false;
            worktime = wawh.Work_Time__c!=null?wawh.Work_Time__c:0;
            if(wawh.Start_Time__c!=null){
                starttime = wawh.Start_Time__c;
                playstyle = 'hide';
                pausestyle = '';
            }
        }
    }
    @AuraEnabled
    public static string getInit(String userid){
        try{
            String issueFieldsQr = '';
            List<field> issueFieldSet = new List<field>();
            List<Schema.FieldSetMember> fieldsetResults = SObjectType.Issue__c.FieldSets.Worker_Assistant.getFields();
            for( Schema.FieldSetMember pfld : fieldsetResults) {
                issueFieldSet.add(new field(pfld.getFieldPath(),pfld.getLabel()));
                issueFieldsQr += ','+pfld.getFieldPath();
            }
            Date tod = System.Today();
            Datetime startDT = Datetime.newInstance(tod.year(),tod.month(),tod.day(),0,0,0);
            if(startDT.format('EEE')!='Sun'){
                startDT = startDT.addDays(-6);
                while(startDT.format('EEE')!='Sun'){
                    startDT = startDT.addDays(1);
                }
            }
            Date startD = Date.newInstance(startDT.year(),startDT.month(),startDT.day());
            List<status> stats= new List<status>();
            Schema.DescribeFieldResult fieldResult = Issue__c.Issue_Status__c.getDescribe();
            for( Schema.PicklistEntry pickListVal : fieldResult.getPicklistValues())    {
                if(pickListVal.isActive())
                    stats.add(new status(pickListVal.getValue(),pickListVal.getLabel()));
            }
            List <Issue__c> issues4up = new List <Issue__c>();
            Map <String, List <Issue__c>> initIssuesByUser = new Map <String, List <Issue__c>>();
            Map <String, List <Issue__c>> issuesByUser = new Map <String, List <Issue__c>>();
            User us = [select id,Worker_Assistant__c,Worker_Assistant_WD_is_Required__c,Name,(select id,Start_Time__c,Scope_Item__c,Issue__c,Work_Time__c,RecordType.Name from WA_Working_Hours__r) from User where id=:userid limit 1];
            Map <String, Issue__feed> feedByIssue = new Map <String, Issue__feed>();
            List <User> otherusers = [select id,Name from User Where id!=:userid and isActive=true and profile.name!=null and (not profile.name  like: '%IT Staff%') and (not profile.name  like: '%Demo%') and (not profile.name  like: '%AppStore%') and (not profile.name  like: '%Analytics%')  and (not profile.name  like: '%API%') and (not profile.name  like: '%Office%') and (not profile.name  like: '%Site%') and (not profile.name  like: '%Survey%') and (not profile.name  like: '%Portal%') and (not profile.name  like: '%Employees%') and (not profile.name  like: '%ITmyWay Internal%') Order by Name];
            Map <String, List <Weekly_Hours__c>> weekliesByUser = new Map <String, List <Weekly_Hours__c>>();
            initIssuesByUser.put(us.id, new List <Issue__c>());
            weekliesByUser.put(us.id, new List <Weekly_Hours__c>());
            for(User aus:otherusers) {
                initIssuesByUser.put(aus.id, new List <Issue__c>());
                weekliesByUser.put(aus.id, new List<Weekly_Hours__c>());
            }
            Set <String> initIssuesByUserSet = initIssuesByUser.keySet();
            List <Issue__c> initissues = Database.query('select id,Parent_Issue__c,Parent_Issue__r.Name,RecordType.Name,Release__c,Release__r.Name,Assigned_To__c,Name,Running__c,Due_Date__c,Start_Date__c,Assigned_To__r.Name,Owner.Name,Issue_Name__c,Queue__c,Account_Name__c,Account_Name__r.name,Project__c,Project__r.name,Scope_Item__c,Scope_Item__r.Name,Issue_Status__c,Delivery_Type__c,Dev_Estimation__c,Login_Details_1__c,Login_Details_1__r.Name, Login_Details_1__r.System_Name__c,Login_URL__c,Deploy_Login_Details__c,Deploy_Login_Details__r.Name, Deploy_Login_Details__r.System_Name__c,Deploy_Login_Details_URL__c,UAT_Login_Details__c,UAT_Login_Details__r.Name, UAT_Login_Details__r.System_Name__c,UAT_Login_URL__c,Budget__c,Working_Days__c,Total_Billable_Hours__c,Total_Hours__c,Customer_Priority__c,Project__r.QA_User__c'+issueFieldsQr+' from Issue__c Where (Issue_Status__c in:openissues OR Issue_Status__c in:qaissues OR (Issue_Status__c not in:closedissues)) and Assigned_To__c in:initIssuesByUserSet and ((Scope_Item__c!=null and Login_Details_1__c!=null) or Issue_Status__c=\'Draft\' or Issue_Status__c=\'New - Portal\') and Account_Name__c!=null Order by Queue__c,LastModifiedDate DESC');
            for(Issue__c is:initissues){
                feedByIssue.put(is.id, new Issue__Feed());
                initIssuesByUser.get(is.Assigned_To__c).add(is);
            }
            List <Issue__Feed> isfeeds = [SELECT id,Parentid,LastModifiedDate,CreatedById,(select id,CreatedDate,CreatedById from FeedComments Order By CreatedDate DESC limit 1) FROM Issue__Feed Where Parentid in:feedByIssue.keySet() Order by Parentid,LastModifiedDate DESC];
            for(Issue__Feed isf:isfeeds){
                String lastused = isf.CreatedById;
                if(isf.FeedComments.size()>0)   lastused = isf.FeedComments[0].CreatedById;
                if(lastused!=userid&&feedByIssue.get(isf.Parentid).id==null){
                    feedByIssue.put(isf.Parentid,isf);
                }
            }
            for(Weekly_Hours__c wkl:[select id,userid__c,Start_Date__c,Sunday_actual_hours__c,Sunday_start_time__c,Sunday_end_time__c,Monday_actual_hours__c,Monday_start_time__c,Monday_end_time__c,Tuesday_actual_hours__c,Tuesday_start_time__c,Tuesday_end_time__c,Wednesday_actual_hours__c,Wednesday_start_time__c,Wednesday_end_time__c,Thursday_actual_hours__c,Thursday_start_time__c,Thursday_end_time__c,Friday_actual_hours__c,Friday_start_time__c,Friday_end_time__c from Weekly_Hours__c where (Start_Date__c=:startD or Start_Date__c=:startD.addDays(7)) and userid__c in:initIssuesByUser.keySet() order by userid__c,Start_Date__c]){
                weekliesByUser.get(wkl.userid__c).add(wkl);
            }
            issuesByUser.put(us.id, new List <Issue__c>());
            for(User aus:otherusers)    issuesByUser.put(aus.id, new List <Issue__c>());
            for(Issue__c is:initIssuesByUser.get(us.id))
                if(qaissues.contains(is.Issue_Status__c)&&is.Project__r.QA_User__c!=us.id&&issuesByUser.containsKey(is.Project__r.QA_User__c))  issuesByUser.get(is.Project__r.QA_User__c).add(is);
                else    issuesByUser.get(us.id).add(is);
            for(User aus:otherusers)
                for(Issue__c is:initIssuesByUser.get(aus.id))
                    if(qaissues.contains(is.Issue_Status__c)&&is.Project__r.QA_User__c!=aus.id&&issuesByUser.containsKey(is.Project__r.QA_User__c)) issuesByUser.get(is.Project__r.QA_User__c).add(is);
                    else    issuesByUser.get(aus.id).add(is);
            integer i=1;
            for(Issue__c is:issuesByUser.get(us.id)){
                if(issueCheck(us.id,is.Issue_Status__c,is.Project__r.QA_User__c)&&is.Queue__c!=null){
                    if(is.Queue__c!=i){is.Queue__c=i;issues4up.add(is);}
                    i++;
                }
            }
            for(Issue__c is:issuesByUser.get(us.id)){
                if(issueCheck(us.id,is.Issue_Status__c,is.Project__r.QA_User__c)&&is.Queue__c==null){is.Queue__c=i;issues4up.add(is);i++;}
            }
            pageData pageData = new pageData();
            List<status> statuses = new List<status>();
            for(status rst:stats){
                status st = new status(rst.value,rst.label);
                if(!closedissues.contains(st.value)){
                    if(customerissues.contains(st.value)){
                        st.sel = false;
                    } else {
                        st.sel = true;
                    }
                    statuses.add(st);
                }
            }
            pageData.statuses = statuses;
            pageData.msg = Label.Worker_Assistant_Message!='NULL'?Label.Worker_Assistant_Message:'';
            pageData.admin = us.Worker_Assistant__c=='Assigner';
            pageData.pm = us.Worker_Assistant__c=='Project Manager'||us.Worker_Assistant__c=='Assigner';
            pageData.user = us.Worker_Assistant__c=='User'||us.Worker_Assistant__c==null;
            pageData.wdRequired = us.Worker_Assistant_WD_is_Required__c;
            pageData.curResource = new resource(us,stats,pageData.admin,pageData.pm,issuesByUser.get(us.id),userid,feedByIssue,weekliesByUser.get(us.id),issueFieldSet);
            Contact con = currentContact.getContactRecord();
            if(con!=null){
                pageData.curResource.conid = con.id;
                pageData.curResource.empType = con.Employee_Type__c;
            }
            pageData.curResource.numiss = pageData.curResource.issues.size();
            pageData.curResource.numown = pageData.curResource.ownedissues.size();
            pageData.curResource.numwait = pageData.curResource.waitingissues.size();
            pageData.curResource.main = pageData.curResource.numown>0?true:false;
            for(User aus:otherusers){
                i=1;
                for(Issue__c is:issuesByUser.get(aus.id)){
                    if(issueCheck(aus.id,is.Issue_Status__c,is.Project__r.QA_User__c)&&is.Queue__c!=null){
                        if(is.Queue__c!=i){ is.Queue__c=i;issues4up.add(is);}
                        i++;
                    }
                }
                for(Issue__c is:issuesByUser.get(aus.id)){
                    if(issueCheck(aus.id,is.Issue_Status__c,is.Project__r.QA_User__c)&&is.Queue__c==null){is.Queue__c=i;issues4up.add(is);i++;}
                }
                resource res = new resource(aus,stats,pageData.admin,pageData.pm,issuesByUser.get(aus.id),userid,feedByIssue,weekliesByUser.get(aus.id),issueFieldSet);
                for(issue is:res.issues)
                    if(is.okview){
                        res.okview = true;
                        if(!pageData.admin) res.showall = false;
                    }
                for(issue is:res.ownedissues)
                    if(is.okview){
                        res.okview = true;
                        if(!pageData.admin) res.showall = false;
                    }
                //fix no issues
                res.numiss = res.issues.size();
                res.numown = res.ownedissues.size();
                pageData.adtResources.add(res);
            }
            if(issues4up.size()>0){update issues4up;return getInit(userid);}
            List <Scope_Item__c> scopes = [select id,name,Start_Date__c,End_Date__c,Running__c,Project__r.Account__c,Project__r.Account__r.Name,Project__c,Project__r.Name,Total_Architect_Budget__c,Total_Dev_Budget__c,Total_implementation_Budget__c,Total_PM_Budget__c,Total_QA_Budget__c,Total_Imp_Working_Billable_Hours__c,Total_Dev_Working_Billable_Hours__c,Total_PM_Working_Billable_Hours__c,Total_Arc_Working_Billable_Hours__c,Total_QA_Working_Billable_Hours__c,ZV_Name__c from Scope_Item__c where Project__r.Status__c='Active' AND Project__r.RecordType.Name='Salesforce' and Status__c!='Ended' Order by Project__r.Name,Start_Date__c];
            for(Scope_Item__c sc:scopes){
                pageData.activeScopes.add(new scope(sc, pageData.curResource.empType));
            }
            pageData.totalHours = 0;
            pageData.billableHours = 0;
            for(Working_Hours__c wh:[select id,CreatedDate,Description_Of_Work__c,Name,Project__c,Project__r.Name,Scope_Item__c,Scope_Item__r.Name,Number_Of_Hours__c,Billable_Hours__c,Issue__c,Issue__r.Name from Working_Hours__c Where Performed_By_2__r.Name=:UserInfo.getName() and Date__c=:System.Today() Order By CreatedDate DESC]){
                pageData.was.add(new wa(wh));
                pageData.totalHours+=(wh.Number_Of_Hours__c!=null?wh.Number_Of_Hours__c:0);
                pageData.billableHours+=(wh.Billable_Hours__c!=null?wh.Billable_Hours__c:0);
            }
            
            //added for wawh
            Map <String,wh> whMap = new Map <String,wh>();
            for(issue is:pageData.curResource.issues)   issueWA(is,us.WA_Working_Hours__r,whMap);
            for(issue is:pageData.curResource.ownedissues)  issueWA(is,us.WA_Working_Hours__r,whMap);
            for(issue is:pageData.curResource.waitingissues)  issueWA(is,us.WA_Working_Hours__r,whMap);
            pageData.curResource.todayWD = new Working_Days__c(Type__c='Work',Performed_By_contact__c=pageData.curResource.conid,Start__c=null,End__c=null);
            pageData.locations = new list <status>();
            Schema.DescribeFieldResult wdResult = Working_Days__c.Location__c.getDescribe();
            for( Schema.PicklistEntry pickListVal : wdResult.getPicklistValues()){
                if(pickListVal.isActive()){
                    status st = new status(pickListVal.getValue(),pickListVal.getLabel());
                    if(pickListVal.isDefaultValue())    st.sel = true;
                    pageData.locations.add(st);
                }
            }
            Map <String,Working_Days__c> wdByContactName = new Map <String,Working_Days__c>();
            Boolean notFnd = true;
            for(Working_Days__c wd:[select id,Location__c,Total_Hours__c,Type__c,Start__c,End__c,Performed_By_contact__c,Performed_By_contact__r.Name from Working_Days__c where Start__c!=null and Start__c>=:tod and Start__c<:tod.addDays(1) and Type__c='Work' and Performed_By_contact__c!=null]){
                if(wd.Performed_By_contact__c==pageData.curResource.conid){
                    notFnd = false;
                    pageData.curResource.todayWD = wd;
                    if(pageData.curResource.todayWD.End__c!=null&&pageData.curResource.todayWD.End__c<System.now()) pageData.curResource.isOffline = true;
                    for(status st:pageData.locations){
                        if(st.value==wd.Location__c)    st.sel = true;
                        else                            st.sel = false;
                    }
                }
                else wdByContactName.put(wd.Performed_By_contact__r.Name, wd);
            }
            if(notFnd) pageData.curResource.isOffline = true;
            for(resource adtUser:pageData.adtResources) {
                if(wdByContactName.containsKey(adtUser.name)){
                    adtUser.todayWD = wdByContactName.get(adtUser.name);
                    if(adtUser.todayWD.End__c!=null&&adtUser.todayWD.End__c<System.now()) adtUser.isOffline = true;
                }
                else adtUser.isOffline = true;
                for(issue is:adtUser.issues)    issueWA(is,us.WA_Working_Hours__r,whMap);
                for(issue is:adtUser.ownedissues)    issueWA(is,us.WA_Working_Hours__r,whMap);
            }
            System.debug(us.WA_Working_Hours__r);
            for(scope sc:pageData.activeScopes) for(WA_Working_Hour__c wawh:us.WA_Working_Hours__r) if(wawh.Scope_Item__c==sc.id){sc.wh = new wh(wawh);whMap.put(sc.id,sc.wh);break;}
            pageData.whMap = JSON.serialize(whMap);
            return JSON.serialize(pageData);
        }   catch(exception e){Throw new AuraException(e.getMessage());}
    }
    public static void issueWA(issue is, List <WA_Working_Hour__c> was, Map <String,wh> whMap){
        for(WA_Working_Hour__c wawh:was) if(wawh.issue__c==is.id){
            if(wawh.RecordType.Name=='Feed'){
                is.lastChatterView = wawh.Start_Time__c;
                if(is.lastChatterPost==null||(is.lastChatterView!=null&&is.lastChatterPost<is.lastChatterView)) is.chatterNotify = false;
            } else {
                is.wh = new wh(wawh);
                whMap.put(is.id,is.wh);
            }
        }
    }
    public static boolean issueCheck(String userid,String status,String projQA){
        return openissues.contains(status)||(projQA!=null&&projQA==userid&&qaissues.contains(status));
    }
    public Static Set <String> customerissues = new Set <String>{'Waiting For Customer Response','On Hold','Ready For Customer QA Production','Ready For Customer QA Sandbox','Ready For Customer QA UAT'};
    public Static Set <String> closedissues = new Set <String>{'Cancelled','Closed','Completed'};
    public Static Set <String> qaissues = new Set <String>{'Ready For QA','Ready For QA After Deploy','Ready For QA After Deploy UAT'};
    public Static Set <String> openissues = new Set <String>{'Draft','Research','Estimation','New','New - Portal','In Progress - Resource','In Progress','Ready For Deploy','Ready For Deploy After Customer QA','Ready For Deploy After Customer QA to UAT','Ready For Deploy to UAT','Resource Monitoring'};
    @AuraEnabled
    public static void saveWAWH(String wawhstr){
        try{
            Map <String, wh> wawh = (Map <String, wh>)JSON.deserialize(wawhstr, Map <String, wh>.class);
            String userid = UserInfo.getUserId();
            Set <String> waids = new Set <String>();
            List <WA_Working_Hour__c> wawh4ins = new List <WA_Working_Hour__c>();
            for(String k:wawh.keyset()){
                WA_Working_Hour__c wa = new WA_Working_Hour__c();
                wa.id = wawh.get(k).id;
                wa.RecordTypeId = [SELECT id from RecordType where name='Hours' and SobjectType='WA_Working_Hour__c' limit 1].id;
                if(k.left(3)=='a0z')    wa.Issue__c = k;
                else                    wa.Scope_Item__c = k;
                wa.User__c = userid;
                wa.Work_Time__c = wawh.get(k).worktime;
                wa.Start_Time__c = wawh.get(k).starttime;
                if((wa.Work_Time__c!=0&&wa.Work_Time__c!=null)||wa.Start_Time__c!=null){
                    waids.add(wa.id);
                    wawh4ins.add(wa);
                }
            }
            List <WA_Working_Hour__c> wawh4del = [select id from WA_Working_Hour__c where User__c=:userid and id not in:waids and RecordType.Name='Hours'];
            if(wawh4del.size()>0)   Database.delete(wawh4del, false);
            upsert wawh4ins;
        }   catch(exception e){Throw new AuraException(e.getMessage());}
    }
    @AuraEnabled
    public static void saveFeedView(String issueid){
        try{            
            String userid = UserInfo.getUserId();
            List <WA_Working_Hour__c> was = [select id,Start_Time__c from WA_Working_Hour__c where User__c=:userid and Issue__c=:issueid and RecordType.Name='Feed' limit 1];
            WA_Working_Hour__c wa = new WA_Working_Hour__c();
            if(was.size()>0)    wa.id = was[0].id;
            wa.RecordTypeId = [SELECT id from RecordType where name='Feed' and SobjectType='WA_Working_Hour__c' limit 1].id;
            wa.Issue__c = issueid;
            wa.User__c = userid;
            wa.Start_Time__c = System.Now();
            upsert wa;
        }   catch(exception e){Throw new AuraException(e.getMessage());}
    }
    @AuraEnabled
    public static void saveWD(String wdstr){
        try{
            Working_Days__c wd = (Working_Days__c)JSON.deserialize(wdstr,Working_Days__c.class);
            upsert wd;
        }   catch(exception e){Throw new AuraException(e.getMessage());}
    }
    @AuraEnabled
    public static Working_Hours__c saveWH(String whstr){
        try{
            Working_Hours__c wh = (Working_Hours__c)JSON.deserialize(whstr,Working_Hours__c.class);
            upsert wh;
            return wh;
        }   catch(exception e){Throw new AuraException(e.getMessage());}
    }
    @AuraEnabled
    public static void saveWAS(String wsstr){
        try{
            List <Working_Hours__c> whs = new List <Working_Hours__c>();
            List <Working_Hours__c> whsnotbill = new List <Working_Hours__c>();
            List <wa> was = (List <wa>)JSON.deserialize(wsstr, List <wa>.class);
            for(wa w:was){
                whs.add(new Working_Hours__c(id=w.id,Number_of_Hours__c=w.num,Billable_Hours__c=w.num,Description_of_Work__c=w.description));
                if(w.notbill)  whsnotbill.add(new Working_Hours__c(id=w.id,Billable_Hours__c=0));
            }
            update whs;
            update whsnotbill;
        }   catch(exception e){Throw new AuraException(e.getMessage());}
    }
    @AuraEnabled
    public static void deleteWA(String recid){
        try{
            delete new Working_Hours__c(id=recid);
        }   catch(exception e){Throw new AuraException(e.getMessage());}
    }
    @AuraEnabled
    public static void reOrder(String userid,String recid, Decimal pos){
        try{
            update new Issue__c(id=recid,Assigned_To__c=userid,Queue__c=pos);
        }   catch(exception e){Throw new AuraException(e.getMessage());}
    }
    @AuraEnabled
    public static void markProgress(String recid){
        try{
            update new Issue__c(id=recid,Issue_Status__c='In Progress');
        }   catch(exception e){Throw new AuraException(e.getMessage());}
    }
    @AuraEnabled
    public static void changeStatus(String recid, String status,Decimal devest){
        try{
            Issue__c is = new Issue__c(id=recid,Issue_Status__c=status);
            if(devest!=null&&devest!=0) is.Dev_Estimation__c = devest;
            update is;
        }   catch(exception e){Throw new AuraException(e.getMessage());}
    }
    @AuraEnabled
    public static void isRunning(String recid, Boolean run){
        try{
            update new Issue__c(id=recid,Running__c=run);
        }   catch(exception e){Throw new AuraException(e.getMessage());}
    }
    public static void genClosingNotes(Set <String> issuesids){
        List <Issue__c> iss = [select id,Closing_Notes__c,(select id,Date__c,Description_of_Work__c,Performed_By_2__r.Name from Working_Hours__r where Performed_By_2__r.Name!=null Order by Date__c) from Issue__c where id in:issuesids];
        for(Issue__c is:iss){
            is.Closing_Notes__c = '';
            for(Working_Hours__c wh:is.Working_Hours__r)    if(wh.Description_of_work__c!=null) is.Closing_Notes__c += wh.Date__c.format()+' - '+wh.Performed_By_2__r.Name+':\n'+wh.Description_of_Work__c+'\n';
        }
        Database.update(iss,false);
    }
    public class cfile{
        @AuraEnabled public String Id;
        @AuraEnabled public String Title;
        @AuraEnabled public String FileType;
        public cfile(ContentDocumentLink lnk){
            Id = lnk.ContentDocumentId;
            Title = lnk.ContentDocument.Title;
            FileType = lnk.ContentDocument.FileType;
        }
    }
    @AuraEnabled
    public static List<cfile> getContentDocs(Id arecordId){   
        List<ContentDocumentLink> CDLs = [SELECT ContentDocumentId,ContentDocument.Title,ContentDocument.FileType FROM ContentDocumentLink WHERE LinkedEntityId = :arecordId];
        List <cfile> entries = new List <cfile>();
        for (ContentDocumentLink nextCDL : CDLs) entries.add(new cfile(nextCDL));
        return entries;
    }
    @AuraEnabled
    public static Map <String, List<Working_Team_Resource__c>> getTeams(List<String> teamids){
        try{
            System.debug(teamids);
            Map <String, List<Working_Team_Resource__c>> TeamsById = new Map <String, List<Working_Team_Resource__c>>();
            for(String k:teamids)  TeamsById.put(k, new List<Working_Team_Resource__c>());
            for(Working_Team_Resource__c wt:[select id,Contact__c,Working_Team__c,Team_Member_Type__c,Contact__r.Name from Working_Team_Resource__c where Working_Team__c in: teamids]){
                TeamsById.get(wt.Working_Team__c).add(wt);
            }
            System.debug(TeamsById);
            return TeamsById;
        }   catch(exception e){Throw new AuraException(e.getMessage());}
    }
    /*public static void fixIssuesWOscope(){
        List <Issue__c> Issues = [select id,Project__c from Issue__c where Scope_Item__c=null];
        Map <String,Scope_Item__c> scopesBykey = new Map <String,Scope_Item__c>();
        List <Scope_Item__c> scopes = [select id,Project__c from Scope_Item__c where Project__c=null];

    }*/
}