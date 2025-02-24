trigger IssueTrigger on Issue__c (before insert, before update) {
    Set <String> usids = new Set<String>();
    Set <String> projids = new Set<String>();
    String usid = Userinfo.getUserId();
    usids.add(usid);
    for(Issue__c is:Trigger.New){
        if(is.Assigned_To__c!=null){
            usids.add(is.Assigned_To__c);
        }
        if(is.Project__c!=null){
            projids.add(is.Project__c);
        }
    }
    Map <String,Project__c> prById = new Map <String,Project__c>([select id,Working_Team__c,Account__r.Working_Team__c from Project__c where id in:projids]);
    List <String> teamids = new List <String>();
    for(Project__c pr:prById.values()){
        if(pr.Working_Team__c!=null)    teamids.add(pr.Working_Team__c);
        if(pr.Account__r.Working_Team__c!=null)    teamids.add(pr.Account__r.Working_Team__c);
    }
    Map <String, List<Working_Team_Resource__c>> teamsById = WorkerAssistantController.getTeams(teamids);
    Map <String, Set<String>> wtrnames = new Map <String, Set<String>>();
    for(String k:teamsById.keySet()){
        wtrnames.put(k, new Set<String>());
        for(Working_Team_Resource__c wtr:teamsById.get(k)){
            wtrnames.get(k).add(wtr.Contact__r.Name);
        }
    }
    Map<Id, User> users = new Map<Id, User>([select id,Name,ContactId,Worker_Assistant__c from User where id in:usids]);
    for(Issue__c is:Trigger.New){
        //std logic
        if(is.Project__c!=null&&is.Assigned_To__c!=null&&(Trigger.isInsert||Trigger.oldMap.get(is.id).Assigned_To__c!=is.Assigned_To__c)&&((is.Assigned_To__c!=usid&&users.get(usid).Worker_Assistant__c!='Assigner'&&users.get(is.Assigned_To__c).Worker_Assistant__c!='Assigner'&&users.get(usid).ContactId==null)||Test.isRunningTest())){
            //check team
            if(prById.get(is.Project__c).Working_Team__c!=null){
                if(!wtrnames.get(prById.get(is.Project__c).Working_Team__c).contains(users.get(is.Assigned_To__c).Name)){
                    is.addError('Assigned Resource is not part of your team');
                }
            } else if(prById.get(is.Project__c).Account__r.Working_Team__c!=null){
                if(!wtrnames.get(prById.get(is.Project__c).Account__r.Working_Team__c).contains(users.get(is.Assigned_To__c).Name)){
                    is.addError('Assigned Resource is not part of your team');
                }
            } else {
                is.addError('No Team assigned to this Account or Project');
            }
        }
    }
}