trigger DeleteOldWDFFromNavInt on Working_Days__c (before delete, after undelete) {
    if(Trigger.isDelete){
        Map<String, String> contactIdbyNavId = new Map<String, String>();
        for(Working_Days__c wd : Trigger.old){
            if(wd.Nav_ID__c != null)
                contactIdbyNavId.put(wd.Nav_ID__c, wd.Performed_By_contact__c);
        }
        if(contactIdbyNavId.size() > 0)
            DeleteOldWHFFromNavIntHelper.deleteWH(contactIdbyNavId);             // Send callout to abra to delete WH
    } else {
        List <Working_Days__c> wds = [select id from Working_Days__c where id in:Trigger.newMap.keySet()];
        for(Working_Days__c wd : wds){
            wd.Nav_ID__c = null;
            wd.Nav_Error__c = null;
            wd.Nav_Last_Synced_on__c = null;
        }
        update wds;
    }
}