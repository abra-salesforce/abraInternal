trigger MonthlyTekenTrigger on Monthly_Teken__c (before insert,after insert) {
    if(Trigger.isBefore){
        for(Monthly_Teken__c mt:Trigger.New){
            mt.Key__c = String.valueOf(mt.Date__c);
        }
    } else {
        Map <Date, String> tekenByDate = new Map<Date, String>();
        for(Monthly_Teken__c mt:Trigger.New){
            tekenByDate.put(mt.Date__c, mt.id);
        }
        List <Monthly_Hours__c> mhs = [select id,Date__c from Monthly_Hours__c where Monthly_Teken__c=null and Date__c in:tekenByDate.keySet()];
        for(Monthly_Hours__c mh:mhs)    mh.Monthly_Teken__c = tekenByDate.get(mh.Date__c);
        update mhs;
    }
}