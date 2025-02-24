trigger calculateDistanceFromGoogle on Travel__c (after update, after insert) {

    set<Id> filteredIdsOfTravel =  new set<Id>();

    for(Travel__c newT : Trigger.new){
        
        if(newT.From__c != null && newT.To_Address__c != null && (Trigger.isInsert || newT.From__c != Trigger.oldMap.get(newT.ID).From__c || newT.To_Address__c != Trigger.oldMap.get(newT.ID).To_Address__c))                             // add only if not null 
            filteredIdsOfTravel.add(newT.ID);
    }
    if(filteredIdsOfTravel.size()>0)    calculateDistanceHellper.sendGoogleAndUpdate(filteredIdsOfTravel); // call apex hellper class
}