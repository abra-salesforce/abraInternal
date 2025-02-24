trigger AutoClosingNotes on Working_Hours__c (after insert,after update) {
    if(Test.isRunningTest()||Label.Auto_Closing_Notes=='1'){
        Set <String> issuesids = new Set <String>();
        for(Working_Hours__c wh:Trigger.new){
            if(Trigger.isInsert || (wh.Issue__c!=Trigger.oldmap.get(wh.id).Issue__c||wh.Date__c!=Trigger.oldmap.get(wh.id).Date__c||wh.Description_of_work__c!=Trigger.oldmap.get(wh.id).Description_of_work__c||wh.Performed_By_2__c!=Trigger.oldmap.get(wh.id).Performed_By_2__c)){
                if(wh.Issue__c!=null)   issuesids.add(wh.Issue__c);
                if(Trigger.isUpdate&&wh.Issue__c!=Trigger.oldmap.get(wh.id).Issue__c&&Trigger.oldmap.get(wh.id).Issue__c!=null)   issuesids.add(Trigger.oldmap.get(wh.id).Issue__c);
            }
        }
        if(issuesids.size()>0)  WorkerAssistantController.genClosingNotes(issuesids);
    }
}