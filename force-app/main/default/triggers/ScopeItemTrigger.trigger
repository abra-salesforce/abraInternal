/**
 * @description       : 
 * @author            : Lioz Elmalem
 * @group             : 
 * @last modified on  : 05-18-2022
 * @last modified by  : Lioz Elmalem
**/
trigger ScopeItemTrigger on Scope_Item__c (before insert, before update, after insert, after update) {
    Set <String> templateIds = new Set <String>();
    for(Scope_Item__c si:Trigger.New){
        if(si.Scope_Template__c!=null){
            templateIds.add(si.Scope_Template__c);
        }
    }
    if(Trigger.isBefore){
        Map <String,Scope_Template__c> templates = new Map <String,Scope_Template__c>([select id,Default_PM_Budget__c,Default_Implementation_Budget__c,Default_Dev_Budget__c,Default_QA_Budget__c,Default_Architect_Budget__c,Scope_Info__c,Name from Scope_Template__c where id in:templateIds]);
        for(Scope_Item__c si:Trigger.New){
            if (Trigger.isInsert) {
                if(si.Scope_Template__c!=null&&templates.containsKey(si.Scope_Template__c)){
                    si.Name = templates.get(si.Scope_Template__c).Name;
                    if(si.Scope_Info__c==null)  si.Scope_Info__c = templates.get(si.Scope_Template__c).Scope_Info__c;
                    if(si.Total_PM_Budget__c==null)  si.Total_PM_Budget__c = templates.get(si.Scope_Template__c).Default_PM_Budget__c;
                    if(si.Total_implementation_Budget__c==null)  si.Total_implementation_Budget__c = templates.get(si.Scope_Template__c).Default_Implementation_Budget__c;
                    if(si.Total_Dev_Budget__c==null)  si.Total_Dev_Budget__c = templates.get(si.Scope_Template__c).Default_Dev_Budget__c;
                    if(si.Total_QA_Budget__c==null)  si.Total_QA_Budget__c = templates.get(si.Scope_Template__c).Default_QA_Budget__c;
                    if(si.Total_Architect_Budget__c==null)  si.Total_Architect_Budget__c = templates.get(si.Scope_Template__c).Default_Architect_Budget__c;
                }
            }
            if (si.Total_QA_Budget__c == null) si.Total_QA_Budget__c = 0;
            if (si.Total_Architect_Budget__c == null) si.Total_Architect_Budget__c = 0;
            if (si.Total_Dev_Budget__c == null) si.Total_Dev_Budget__c = 0;
            if (si.Total_implementation_Budget__c == null) si.Total_implementation_Budget__c = 0;
            if (si.Total_PM_Budget__c == null) si.Total_PM_Budget__c = 0;
        }
    } else {
        List<Planned_Time_Per_Week__c> planned4delete = new List <Planned_Time_Per_Week__c>();
        Map<Date, Planned_Time_Per_Week__c> planned4upsert = new Map<Date, Planned_Time_Per_Week__c>();
        Set <String> siids = new Set <String>();
        for(Scope_Item__c si:Trigger.New){
            siids.add(si.id);
        }
        Map<String,Map<Date,Planned_Time_Per_Week__c>> ptpws = MonthlyController.getPlannedWeeklies(siids);
        for(Scope_Item__c si:Trigger.New){
            if(si.Start_Date__c!=null&&si.End_Date__c!=null&&(Trigger.isInsert||si.Start_Date__c!=Trigger.oldMap.get(si.Id).Start_Date__c||si.End_Date__c!=Trigger.oldMap.get(si.Id).End_Date__c||
                                                            si.Total_PM_Budget__c!=Trigger.oldMap.get(si.Id).Total_PM_Budget__c||
                                                            si.Total_implementation_Budget__c!=Trigger.oldMap.get(si.Id).Total_implementation_Budget__c||
                                                             si.Total_Dev_Budget__c!=Trigger.oldMap.get(si.Id).Total_Dev_Budget__c||
                                                             si.Total_QA_Budget__c!=Trigger.oldMap.get(si.Id).Total_QA_Budget__c||
                                                             si.Total_Architect_Budget__c!=Trigger.oldMap.get(si.Id).Total_Architect_Budget__c)){
                
                Map<Date,Planned_Time_Per_Week__c> existingPlanned = ptpws.get(si.id);

                //planned per week
                Map <Date, Planned_Time_Per_Week__c> newPlanned = MonthlyController.createPlannedWeekliesBase(si);
                if(Trigger.isInsert){
                    Map<Date, Planned_Time_Per_Week__c> newPlannedQA = new Map<Date, Planned_Time_Per_Week__c>();
                    Map<Date, Planned_Time_Per_Week__c> newPlannedArchitect = new Map<Date, Planned_Time_Per_Week__c>();
                    Map<Date, Planned_Time_Per_Week__c> newPlannedDevelopment = new Map<Date, Planned_Time_Per_Week__c>();
                    Map<Date, Planned_Time_Per_Week__c> newPlannedImplementation = new Map<Date, Planned_Time_Per_Week__c>();
                    Map<Date, Planned_Time_Per_Week__c> newPlannedProjectManagement = new Map<Date, Planned_Time_Per_Week__c>();
                    try{
                        newPlannedQA = MonthlyController.createPlannedWeeklies(si, 'Total_QA_Budget__c', 'Budget_QA__c', Trigger.isInsert, existingPlanned); 
                    } catch(exception e){si.addError(e.getMessage());}
                    for (Date d : newPlannedQA.keySet()) {
                        newPlanned.get(d).Budget_QA__c = newPlannedQA.get(d).Budget_QA__c;
                    }
                    try{
                        newPlannedArchitect = MonthlyController.createPlannedWeeklies(si, 'Total_Architect_Budget__c', 'Budget_System_Architect__c', Trigger.isInsert, existingPlanned); 
                    } catch(exception e){si.addError(e.getMessage());}
                    for (Date d : newPlannedArchitect.keySet()) {
                        newPlanned.get(d).Budget_System_Architect__c = newPlannedArchitect.get(d).Budget_System_Architect__c;
                    }
                    try{
                        newPlannedDevelopment = MonthlyController.createPlannedWeeklies(si, 'Total_Dev_Budget__c', 'Budget_Developer__c', Trigger.isInsert, existingPlanned); 
                    } catch(exception e){si.addError(e.getMessage());}
                    for (Date d : newPlannedDevelopment.keySet()) {
                        newPlanned.get(d).Budget_Developer__c = newPlannedDevelopment.get(d).Budget_Developer__c;
                    }
                    try{
                        newPlannedImplementation = MonthlyController.createPlannedWeeklies(si, 'Total_implementation_Budget__c', 'Budget_Implementation_Specialist__c', Trigger.isInsert, existingPlanned); 
                    } catch(exception e){si.addError(e.getMessage());}
                    for (Date d : newPlannedDevelopment.keySet()) {
                        newPlanned.get(d).Budget_Implementation_Specialist__c = newPlannedImplementation.get(d).Budget_Implementation_Specialist__c;
                    }
                    try{
                        newPlannedProjectManagement = MonthlyController.createPlannedWeeklies(si, 'Total_PM_Budget__c', 'Budget_PM__c', Trigger.isInsert, existingPlanned); 
                    } catch(exception e){si.addError(e.getMessage());}
                    for (Date d : newPlannedProjectManagement.keySet()) {
                        newPlanned.get(d).Budget_PM__c = newPlannedProjectManagement.get(d).Budget_PM__c;
                    }
                }
                //update or insert
                for(Date d:newPlanned.keySet()){
                    if(existingPlanned.containsKey(d)){
                        /*if(si.Start_Date__c <= d && si.End_Date__c >= d && ((existingPlanned.get(d).Budget_PM__c!=newPlanned.get(d).Budget_PM__c && newPlanned.get(d).Budget_PM__c != null)||(existingPlanned.get(d).Budget_Implementation_Specialist__c!=newPlanned.get(d).Budget_Implementation_Specialist__c && newPlanned.get(d).Budget_Implementation_Specialist__c != null)||(existingPlanned.get(d).Budget_Developer__c!=newPlanned.get(d).Budget_Developer__c && newPlanned.get(d).Budget_Developer__c != null)||(existingPlanned.get(d).Budget_System_Architect__c!=newPlanned.get(d).Budget_System_Architect__c && newPlanned.get(d).Budget_System_Architect__c != null)||(existingPlanned.get(d).Budget_QA__c!=newPlanned.get(d).Budget_QA__c && newPlanned.get(d).Budget_QA__c != null))){
                            Planned_Time_Per_Week__c pt = existingPlanned.get(d);
                            pt.Budget_PM__c = newPlanned.get(d).Budget_PM__c;
                            pt.Budget_Implementation_Specialist__c = newPlanned.get(d).Budget_Implementation_Specialist__c;
                            pt.Budget_Developer__c = newPlanned.get(d).Budget_Developer__c;
                            pt.Budget_QA__c = newPlanned.get(d).Budget_QA__c;
                            pt.Budget_System_Architect__c = newPlanned.get(d).Budget_System_Architect__c;
                            planned4upsert.put(d, pt);
                        }*/
                    }
                    else {
                        planned4upsert.put(d, newPlanned.get(d));
                    }
                }

                // Delete
                for(Date d:existingPlanned.keySet()){
                    if(!newPlanned.containsKey(d) && (si.Start_Date__c > d || si.End_Date__c < d)){
                        planned4delete.add(existingPlanned.get(d));
                    }
                }

                System.debug('After Project Management');
                System.debug(JSON.serialize(planned4upsert));
            }
        }
        if(planned4delete.size()>0)     delete planned4delete;
        if(planned4upsert.values().size()>0)     upsert planned4upsert.values();
        
    }
}