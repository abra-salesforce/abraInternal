trigger OpportunityClosedWon on Opportunity (after update) {
    Date dat = System.Today();
    String sfmasterId = [select id from RecordType where SobjectType = 'Project__c' and Name = 'Salesforce Master' limit 1].id;
    String sfId = [select id from RecordType where SobjectType = 'Project__c' and Name = 'Salesforce' limit 1].id;
    Set <String> accIds = new Set<String>();
    Map <String, Map <String,List <Scope_Item__c>>> scopesByCatBYOppId = new Map <String, Map <String,List <Scope_Item__c>>>();
    Map <String, Opportunity> oppById = new Map <String, Opportunity>();
    for(Opportunity opp:Trigger.new){
        if(opp.StageName=='Closed Won'&&opp.StageName!=Trigger.oldMap.get(opp.id).StageName){
            accIds.add(opp.AccountId);
            oppById.put(opp.Id, opp);
            scopesByCatBYOppId.put(opp.Id, new Map <String,List <Scope_Item__c>>());
        }
    }
    Map <String, Account> accs = new Map<String, Account>([select id,name from Account where id in:accIds]);
    for(Scope_Item__c si:[select id,Opportunity__c,Scope_Template__r.Category__c from Scope_Item__c where Project__c=null and Opportunity__c in:scopesByCatBYOppId.keySet() and Scope_Template__c!=null]){
        if(!scopesByCatBYOppId.get(si.Opportunity__c).containsKey(si.Scope_Template__r.Category__c))   scopesByCatBYOppId.get(si.Opportunity__c).put(si.Scope_Template__r.Category__c, new List<Scope_Item__c>());
        scopesByCatBYOppId.get(si.Opportunity__c).get(si.Scope_Template__r.Category__c).add(si);
    }
    Map <String, Project__c> masterProjs = new Map<String, Project__c>();
    for(Project__c proj:[select id,Account__c from Project__c where Account__c in:accIds and RecordTypeId=:sfmasterId]){
        masterProjs.put(proj.Account__c, proj);
    }
    for(String accId:accs.KeySet()){
        if(!masterProjs.containsKey(accId)){
            masterProjs.put(accId, new Project__c(
                RecordTypeId = sfmasterId,
                Account__c = accId,
                Status__c = 'Active',
                Name = accs.get(accId).Name+' - Master',
                Start_Date__c = dat,
                Billing_Type__c = 'Hourly'
            ));
        }
    }
    upsert masterProjs.values();
    Map <String, Map <String,Project__c>> projs4insMap = new Map <String, Map <String,Project__c>>();
    List <Project__c> projs4ins = new List <Project__c>();
    for(String oppId:scopesByCatBYOppId.keySet()){
        for(String projName:scopesByCatBYOppId.get(oppId).keySet()){
            Project__c newP = new Project__c(
                RecordTypeId = sfId,
                Account__c = oppById.get(oppId).AccountId,
                Parent_Project__c = masterProjs.get(oppById.get(oppId).AccountId).Id,
                Status__c = 'Active',
                Name = accs.get(oppById.get(oppId).AccountId).Name+' - '+projName,
                Start_Date__c = dat,
                Billing_Type__c = 'Hourly'
            );
            if(!projs4insMap.containsKey(oppId))   projs4insMap.put(oppId, new Map <String, Project__c>());
            projs4insMap.get(oppId).put(projName, newP);
            projs4ins.add(newP);
        }
    }
    if(projs4ins.size()>0)  insert projs4ins;
    List <Scope_Item__c> si4up = new List <Scope_Item__c>();
    for(String oppId:scopesByCatBYOppId.keySet()){
        for(String projName:scopesByCatBYOppId.get(oppId).keySet()){
            for(Scope_Item__c si:scopesByCatBYOppId.get(oppId).get(projName)){
                si.Project__c = projs4insMap.get(oppId).get(projName).Id;
                si4up.add(si);
            }
        }
    }
    if(si4up.size()>0)  update si4up;
}