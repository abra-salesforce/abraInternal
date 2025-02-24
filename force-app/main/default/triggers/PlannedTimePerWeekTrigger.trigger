trigger PlannedTimePerWeekTrigger on Planned_Time_Per_Week__c (after update,after insert,after undelete) {
    if(Trigger.isUpdate){
        List <Resource_Planning_Per_Week__c> rppws = new List <Resource_Planning_Per_Week__c>();
        List <Planned_Time_Per_Week__c> pp4up = new List <Planned_Time_Per_Week__c>();
        Set <String> ptids = new Set <String>();
        Set <String> assginedTeamRes = new Set <String>();

        for(Planned_Time_Per_Week__c pt:Trigger.New){
            ptids.add(pt.id);
            if(pt.Assign_Working_Team_Resource__c!=null)   assginedTeamRes.add(pt.Assign_Working_Team_Resource__c);
        }
        Map <String, Working_Team_Resource__c> wtrByid = new Map <String, Working_Team_Resource__c>([select id,Contact__r.Allow_plan_on_all_teams__c,Contact__r.Employee_Type__c from Working_Team_Resource__c where id in:assginedTeamRes]);
        Map <String,Planned_Time_Per_Week__c> ptById = new Map <String,Planned_Time_Per_Week__c>([select id,Scope_Item__r.Project__c,Scope_Item__r.Project__r.Working_Team__c,Scope_Item__r.Project__r.Account__r.Working_Team__c,(select id,Planned_Time_Per_Week__c,Working_Team_Resource__c from Resources_Planning_Per_Week__r) from Planned_Time_Per_Week__c where id in:ptids]);
        Map <String,Map<String,String>> resByPtid = new Map <String,Map<String,String>>();
        List <String> teamids = new List <String>();
        for(Planned_Time_Per_Week__c pt:ptById.values()){
            if(pt.Scope_Item__r.Project__c!=null){
                if(pt.Scope_Item__r.Project__r.Working_Team__c!=null)    teamids.add(pt.Scope_Item__r.Project__r.Working_Team__c);
                if(pt.Scope_Item__r.Project__r.Account__r.Working_Team__c!=null)    teamids.add(pt.Scope_Item__r.Project__r.Account__r.Working_Team__c);
            }
            resByPtid.put(pt.Id, new Map <String,String>());
            for(Resource_Planning_Per_Week__c rppw:pt.Resources_Planning_Per_Week__r){
                resByPtid.get(pt.Id).put(rppw.Working_Team_Resource__c,rppw.id);
            }
        }
        Map <String, List<Working_Team_Resource__c>> teamsById = WorkerAssistantController.getTeams(teamids);
        Map <String, Set<String>> wtrids = new Map <String, Set<String>>();
        for(String k:teamsById.keySet()){
            wtrids.put(k, new Set<String>());
            for(Working_Team_Resource__c wtr:teamsById.get(k)){
                wtrids.get(k).add(wtr.id);
            }
        }
        for(Planned_Time_Per_Week__c pt:Trigger.New){
            if(pt.Assign_Budget__c!=null&&pt.Assign_Working_Team_Resource__c!=null&&ptById.get(pt.Id).Scope_Item__r.Project__c!=null){
                if(wtrByid.get(pt.Assign_Working_Team_Resource__c).Contact__r.Employee_Type__c!='Developer'&&wtrByid.get(pt.Assign_Working_Team_Resource__c).Contact__r.Employee_Type__c!='System Architect'){
                    if(ptById.get(pt.Id).Scope_Item__r.Project__r.Working_Team__c!=null){
                        if(!wtrids.get(ptById.get(pt.Id).Scope_Item__r.Project__r.Working_Team__c).contains(pt.Assign_Working_Team_Resource__c)&&wtrByid.get(pt.Assign_Working_Team_Resource__c).Contact__r.Allow_plan_on_all_teams__c!=true){
                            pt.addError('Assigned Resource is not part of your team');
                        }
                    } else if(ptById.get(pt.Id).Scope_Item__r.Project__r.Account__r.Working_Team__c!=null){
                        if(!wtrids.get(ptById.get(pt.Id).Scope_Item__r.Project__r.Account__r.Working_Team__c).contains(pt.Assign_Working_Team_Resource__c)&&wtrByid.get(pt.Assign_Working_Team_Resource__c).Contact__r.Allow_plan_on_all_teams__c!=true){
                            pt.addError('Assigned Resource is not part of your team');
                        }
                    } else {
                        pt.addError('No Team assigned to this Account or Project');
                    }
                }
                Resource_Planning_Per_Week__c rppw = new Resource_Planning_Per_Week__c(Planned_Time_Per_Week__c=pt.id,Hours_Assigned__c=pt.Assign_Budget__c,Working_Team_Resource__c=pt.Assign_Working_Team_Resource__c);
                if(resByPtid.containsKey(pt.id)&&resByPtid.get(pt.id).containsKey(pt.Assign_Working_Team_Resource__c))  rppw.id = resByPtid.get(pt.id).get(pt.Assign_Working_Team_Resource__c);
                rppws.add(rppw);
            }
            if(pt.Assign_Budget__c!=null||pt.Assign_Working_Team_Resource__c!=null){
                pp4up.add(new Planned_Time_Per_Week__c(id=pt.id, Assign_Budget__c = null, Assign_Working_Team_Resource__c = null));
            }
        }
        if(pp4up.size()>0)  update pp4up;
        if(rppws.size()>0)  upsert rppws;
    } else {
        Set <String> scopeids = new Set <String>();
        Date minDate = null;
        Date maxDate = null;
        for(Planned_Time_Per_Week__c pt:Trigger.New){
            scopeids.add(pt.Scope_Item__c);
        }
        List <Working_Hours__c> whs4fix = [select id,Scope_Item__c,Date__c from Working_Hours__c where Scope_Item__c in: scopeids and Planned_Time_Per_Week__c=null];
        Map <String,Scope_Item__c> scopes = new Map <String,Scope_Item__c>([select id,(select Id,Start_Date__c from Planned_Time_Per_Weeks__r) from Scope_Item__c where Id in: scopeids]);
        Map <String,Working_Hours__c> whs4up = new  Map <String,Working_Hours__c>();
        for(Working_Hours__c wh:whs4fix){
            wh.Planned_Time_Per_Week__c = null;
            if(scopes.containsKey(wh.Scope_Item__c)){
                Date startW = MonthlyController.sundayStartWeek(wh.Date__c);
                for(Planned_Time_Per_Week__c pl:scopes.get(wh.Scope_Item__c).Planned_Time_Per_Weeks__r){
                    if(pl.Start_Date__c == startW){
                        wh.Planned_Time_Per_Week__c = pl.id;
                        whs4up.put(wh.id, wh);
                        break;
                    }
                }
            }
        }
        if(whs4up.size()>0) update whs4up.values();
    }
}