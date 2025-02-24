trigger DeleteOldWHFFromNavInt on Working_Hours__c (before delete, after undelete, after update) {
    Map<String, String> contactIdbyNavId = new Map<String, String>();
    if(Trigger.isDelete){
        for(Working_Hours__c wh : Trigger.old){
            if(wh.Nav_ID__c != null)
                contactIdbyNavId.put(wh.Nav_ID__c, wh.Performed_By_2__c);
            if(wh.Nav_ID_Non_Billable__c != null)
                contactIdbyNavId.put(wh.Nav_ID_Non_Billable__c, wh.Performed_By_2__c);
        }
    } else if(Trigger.isUndelete){
        List <Working_Hours__c> whs = [select id from Working_Hours__c where id in:Trigger.newMap.keySet()];
        for(Working_Hours__c wh : whs){
            wh.Nav_ID__c = null;
            wh.Nav_ID_Non_Billable__c = null;
            wh.Nav_Error__c = null;
            wh.Nav_Error_Non_Billable__c = null;
            wh.Nav_Last_Synced_on__c = null;
        }
        update whs;
    } else if(Trigger.isUpdate){
        Set <String> bill4del = new Set <String>();
        Set <String> Nbill4del = new Set <String>();

        for(Working_Hours__c wh : Trigger.new){
            if(wh.Nav_ID__c != null && wh.Billable_Hours__c!=null && wh.Billable_Hours__c<=0){
                contactIdbyNavId.put(wh.Nav_ID__c, wh.Performed_By_2__c);
                bill4del.add(wh.id);
            }
            if(wh.Nav_ID_Non_Billable__c != null && wh.Billable_Hours__c!=null && wh.Number_of_hours__c!=null && (wh.Number_of_hours__c-wh.Billable_Hours__c)<=0){
                contactIdbyNavId.put(wh.Nav_ID_Non_Billable__c, wh.Performed_By_2__c);
                Nbill4del.add(wh.id);
            }
        }
        List <Working_Hours__c> whs = [select id from Working_Hours__c where id in:bill4del or id in:Nbill4del];
        for(Working_Hours__c wh:whs){
            if(bill4del.contains(wh.id)){
                wh.Nav_Id__c = null;
                wh.Nav_Error__c = null;
            }
            if(Nbill4del.contains(wh.id)){
                wh.Nav_Id_Non_Billable__c = null;
                wh.Nav_Error_Non_Billable__c = null;
            }
        }
        update whs;
    }
    if(contactIdbyNavId.size() > 0)
        DeleteOldWHFFromNavIntHelper.deleteWH(contactIdbyNavId);             // Send callout to abra to delete WH
}