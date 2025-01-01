public with sharing class AsyncNavIntegrationQueueable implements Queueable, Database.AllowsCallouts{
    public static final Integer     batchSize = 50;
    private ID                      lastIdRecWHThatSynced;
    private ID                      lastIdRecWDThatSynced;
    public AsyncNavIntegrationQueueable(ID lastIdRecWHThatSynced, ID lastIdRecWDThatSynced){
        this.lastIdRecWHThatSynced = lastIdRecWHThatSynced;
        this.lastIdRecWDThatSynced = lastIdRecWDThatSynced;
    }
    public void execute(QueueableContext context){
        Nav_Setting__mdt sett = getSettings();
        List <Working_Hours__c> whs = getwhs(this.lastIdRecWHThatSynced);
        List <Working_Days__c> wds = getwds(this.lastIdRecWDThatSynced);
        HttpResponse resWH = null;
        HttpResponse resWD = null;
        Map <String,Working_Hours__c> idWHMap = new Map<String,Working_Hours__c>();
        for(Working_Hours__c wh:whs){
            if(wh.Billable_Hours__c>0)  idWHMap.put(wh.id+';true', wh);
            if(wh.Non_Billable_Hours__c>0)  idWHMap.put(wh.id+';false', wh);
        }
        Map <String,Working_Days__c> idWDMap = new Map<String,Working_Days__c>(wds);                                                 
        if(!whs.isEmpty()){
            this.lastIdRecWHThatSynced = whs[whs.size()-1].id;
            String jsonToSend = NavIntegration.createJsonForAllWH(whs);             // Create WH list json like wanted
            resWH = calloutToAbra(jsonToSend, sett);                           // Make callout & get response
        }
        if(!wds.isEmpty()){
            this.lastIdRecWDThatSynced = wds[wds.size()-1].id;
            String jsonToSend = NavIntegration.createJsonForAllWD(wds);             // Create WH list json like wanted
            resWD = calloutToAbra(jsonToSend, sett);                           // Make callout & get response
        }
        if(resWH!=null){
            if(resWH.getStatusCode() == 200){
                List<NavIntegration.InnerClass> navInnerClassesForJson = NavIntegration.parse(resWH.getBody());
                List<Working_Hours__c> finalWhs = updateFittingWorkingHoursWithNavInfo(idWHMap, navInnerClassesForJson);
                Database.update(finalWhs, false);
                System.debug('workingHours: ' + finalWhs);     // Update all working hours
            } else {
                List<Working_Hours__c> finalWhs = updateErrors(idWHMap, resWH.getBody());
                Database.update(finalWhs, false);
                System.debug('workingHours with errors: ' + finalWhs);     // Update all working hours
            }
        }
        if(resWD!=null){
            if(resWD.getStatusCode() == 200){
                List<NavIntegration.InnerClass> navInnerClassesForJson = NavIntegration.parse(resWD.getBody());
                List<Working_Days__c> finalWds = updateFittingWorkingDaysWithNavInfo(idWDMap, navInnerClassesForJson);
                Database.update(finalWds, false);
                System.debug('workingDays: ' + finalWds);     // Update all working hours
            } else {
                List<Working_Days__c> finalWds = updateErrors(idWDMap, resWD.getBody());
                Database.update(finalWds, false);
                System.debug('workingDays with errors: ' + finalWds);     // Update all working hours
            }
        }
        if((whs.size() == batchSize || wds.size() == batchSize) && !Test.isRunningTest()) 
            System.enqueueJob(new AsyncNavIntegrationQueueable(lastIdRecWHThatSynced, lastIdRecWDThatSynced));
    }
    public static List <Working_Hours__c> getWHs(String lastIdRecWHThatSynced){
        return ((List <Working_Hours__c>) Database.query('SELECT Id, Non_Billable_Hours__c, Billable_Hours__c, Nav_ID__c, Nav_ID_Non_Billable__c, Working_Day__c, Date__c, WH_Type__c, Project__r.Parent_Project__r.Project_Number__c, Project__r.Project_Number__c, Description_Of_Work__c, Performed_By_2__r.Email, Performed_By_2__r.Department, Working_Day__r.Location__c, RecordType.Name, Start__c, End__c FROM Working_Hours__c WHERE Nav_Needs_To_Be_Synced__c = true'+(lastIdRecWHThatSynced!=null?' and ID >: lastIdRecWHThatSynced':'')+' Order By Id LIMIT : batchSize'));
    }
    public static List <Working_Days__c> getWDs(String lastIdRecWDThatSynced){
        return ((List <Working_Days__c>) Database.query('SELECT Id, Nav_Type__c, Nav_ID__c, Start__c, End__c, Performed_By_contact__r.Email, Performed_By_contact__r.Department FROM Working_Days__c WHERE Nav_Needs_To_Be_Synced__c = true'+(lastIdRecWDThatSynced!=null?' and ID >: lastIdRecWDThatSynced':'')+' Order By Id LIMIT : batchSize'));
    }
    public static Nav_Setting__mdt getSettings(){
        String org = ([SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox)?'Sandbox':'Production';
        return [select id,Endpoint__c,Api_Key__c from Nav_Setting__mdt where DeveloperName=:org limit 1]; 
    }
    public static HttpResponse calloutToAbra(String body,Nav_Setting__mdt sett){
        //Set HTTPRequest Method
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setTimeout(120000);
        req.setHeader('ApiKey', sett.Api_Key__c);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setEndpoint(sett.Endpoint__c+'v1/BulkInsertTimesheet/ITmyway');
        // setting body
        System.debug('Input Request:' + body);
        req.setBody(body);
        //Execute web service call here     
        Http http = new Http();
        HTTPResponse res = new HttpResponse();
        if(!Test.isRunningTest()) res = http.send(req);
        else {
            res.setBody(body);
            res.setStatusCode(200);
        }
        //Helpful debug messages
        System.debug(res.toString()); 
        System.debug('STATUS:' + res.getStatus());
        System.debug('STATUS_CODE:' + res.getStatusCode());
        System.debug('response:' + res.getBody()); 
        return res;
    }
    private static List<Working_Hours__c> updateFittingWorkingHoursWithNavInfo(Map <string,Working_Hours__c> idWHMap, List<NavIntegration.InnerClass> navInnerClassesFromJson){ 
        Map<String,Working_Hours__c> workingHours = new Map<String,Working_Hours__c>();
        for(NavIntegration.InnerClass innerC : navInnerClassesFromJson){        // Go over each inner class
            String oppositeId = innerC.param1.split(';')[0]+';'+(innerC.param1.split(';')[1]=='true'?'false':'true');
            Working_Hours__c wh = idWHMap.get(innerC.param1);              // Find matching working hours from map
            if(innerC.billable==true){
                wh.Nav_ID__c = innerC.id!='0'&&innerC.id!=null?innerC.id:(Test.isRunningTest()?'0':null);
                wh.Nav_Error__c = innerC.ErrorMessage;
                wh.Has_Nav_Error__c = innerC.ErrorMessage!=null&&innerC.ErrorMessage!=''?true:false;
            }
            else{
                wh.Nav_ID_Non_Billable__c = innerC.id!='0'&&innerC.id!=null?innerC.id:(Test.isRunningTest()?'0':null);
                wh.Nav_Error_Non_Billable__c = innerC.ErrorMessage;
                wh.Has_Nav_Error_Non_Billable__c = innerC.ErrorMessage!=null&&innerC.ErrorMessage!=''?true:false;
            }
            //delete error on non exst hours
            if(!idWHMap.containsKey(oppositeId)){
                if(innerC.billable==true){
                    wh.Nav_Error_Non_Billable__c = null;
                    wh.Has_Nav_Error_Non_Billable__c = false;
                }
                else{
                    wh.Nav_Error__c = null;
                    wh.Has_Nav_Error__c = false;
                }
            }
            wh.Nav_Last_Synced_On__c = System.now().addMinutes(5);
            workingHours.put(wh.id, wh);
        }
        return workingHours.values();
    }
    private static List<Working_Hours__c> updateErrors(Map <string,Working_Hours__c> idWHMap, String errorMsg){
        Map<String,Working_Hours__c> workingHours = new Map<String,Working_Hours__c>();
        for(String whid : idWHMap.keySet()){        // Go over each inner class
            Working_Hours__c wh = idWHMap.get(whid);              // Find matching working hours from map
            wh.Nav_Last_Synced_On__c = System.now().addMinutes(5);
            wh.Nav_Error__c = errorMsg;
            wh.Nav_Error_Non_Billable__c = errorMsg;
            wh.Has_Nav_Error__c = true;
            wh.Has_Nav_Error_Non_Billable__c = true;
            workingHours.put(wh.id, wH);
        }
        return workingHours.values();
    }
    private static List<Working_Days__c> updateFittingWorkingDaysWithNavInfo(Map <string,Working_Days__c> idWDMap, List<NavIntegration.InnerClass> navInnerClassesFromJson){ 
        List<Working_Days__c> workingDays = new List<Working_Days__c>();
        for(NavIntegration.InnerClass innerC : navInnerClassesFromJson){        // Go over each inner class
            Working_Days__c wd = idWDMap.get(innerC.param1);              // Find matching working hours from map
            wd.Nav_ID__c = innerC.id!='0'&&innerC.id!=null?innerC.id:(Test.isRunningTest()?'0':null);
            DateTime dt = System.now();
            wd.Nav_Last_Synced_On__c = dt.addMinutes(1);
            wd.Nav_Error__c = innerC.ErrorMessage;
            wd.Has_Nav_Error__c = innerC.ErrorMessage!=null&&innerC.ErrorMessage!=''?true:false;
            workingDays.add(wd);
        }
        return workingDays;
    }
    private static List<Working_Days__c> updateErrors(Map <string,Working_Days__c> idWDMap, String errorMsg){
        List<Working_Days__c> workingDays = new List<Working_Days__c>();
        for(String wdid : idWDMap.keySet()){        // Go over each inner class
            Working_Days__c wd = idWDMap.get(wdid);              // Find matching working hours from map
            DateTime dt = System.now();
            wd.Nav_Last_Synced_On__c = dt.addMinutes(1);
            wd.Nav_Error__c = errorMsg;
            wd.Has_Nav_Error__c = true;
            workingDays.add(wd);
        }
        return workingDays;
    }
}