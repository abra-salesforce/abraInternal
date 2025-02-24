trigger ResourcePlanningPerWeekEmployeeTrigger on Resource_Planning_Per_Week__c(before insert, before update) {
    Map<String, String> empType = new Map<String, String>();
    Map<Integer, String> resources = new Map<Integer, String>();
    for (Integer index=0; index < Trigger.new.size(); index++) {
        Resource_Planning_Per_Week__c resource = Trigger.new[index];
        if (resource.Working_Team_Resource__c != null) 
                resources.put(index, resource.Working_Team_Resource__c);
    }
    
    List<Resource_Planning_Per_Week__c> resourcesToUpdate = new List<Resource_Planning_Per_Week__c>();
    for (Working_Team_Resource__c team : [SELECT Id, Contact__r.Employee_Type__c FROM Working_Team_Resource__c WHERE Id IN: resources.values()]) 
        empType.put(team.Id, team.Contact__r.Employee_Type__c);
    for (Integer index=0; index < Trigger.new.size(); index++) {
        if(empType.containsKey(Trigger.new[index].Working_Team_Resource__c))
        	Trigger.new[index].Employee_Type__c = empType.get(Trigger.new[index].Working_Team_Resource__c);
    }
    
}