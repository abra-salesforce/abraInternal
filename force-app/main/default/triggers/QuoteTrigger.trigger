trigger QuoteTrigger on Quote (before insert) {
	Map <Integer,Opportunity> oppByIndex = new Map <Integer,Opportunity>();
    Id ITRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('IT').getRecordTypeId();
    for(Integer i=0;i<Trigger.New.size();i++){
        Quote qt = Trigger.New[i];
        if(qt.OpportunityId==null&&qt.Account__c!=null){
            oppByIndex.put(i, new Opportunity(
                Name = qt.Name,
                RecordTypeId = ITRecordTypeId,
                AccountId = qt.Account__c,
                StageName = 'Proposal/Price Quote',
                CloseDate = (System.Today().addMonths(1)),
                Project_Start_Date_Planned__c = (System.Today().addMonths(1))
            ));
        }
    }
    insert oppByIndex.values();
    for(Integer i=0;i<Trigger.New.size();i++){
        Quote qt = Trigger.New[i];
        if(qt.OpportunityId==null&&qt.Account__c!=null){
            qt.OpportunityId = oppByIndex.get(i).Id;
        }
    }
}