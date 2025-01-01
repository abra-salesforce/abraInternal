public with sharing class ConAndDisWorkingHourToDay {
    public static void fixDataFromWorkingDays(List <Working_Days__c> wds){
        Map <String, String> wdBykey = new Map <String, String>();
        Map <String, List<Working_Hours__c>> whsByKey = new Map <String, List<Working_Hours__c>>();
        Set <String> missingContactsForWhs = new Set <String>();
        Set <Date> missingDatesForWhs = new Set <Date>();
        //gather all working days by key
        for (Working_Days__c wd : wds){
            String key = wd.Performed_By_contact__c+';'+dateToStr(wd.Date__c);
            wdBykey.put(key, wd.id);
            whsByKey.put(key, new List<Working_Hours__c>());
            missingContactsForWhs.add(wd.Performed_By_contact__c);
            missingDatesForWhs.add(wd.Date__c);
        }
        
        Set <String> missingContacts = new Set <String>();
        Set <Date> missingDates = new Set <Date>();
        //gather all working hours by key and find missing keys
        for(Working_Hours__c wh:[SELECT Id, Working_Day__c, Date__c, Contact__c, Performed_By_2__c FROM Working_Hours__c WHERE (Working_Day__c in: wdBykey.values() OR (Working_Day__c=null AND Performed_By_2__c in:missingContactsForWhs AND Date__c in:missingDatesForWhs))]){
            String key = wh.Performed_By_2__c+';'+dateToStr(wh.Date__c);
            if(whsByKey.containsKey(key))    whsByKey.get(key).add(wh);
            else{
                missingContacts.add(wh.Performed_By_2__c);
                missingDates.add(wh.Date__c);
                whsByKey.put(key, new List<Working_Hours__c>{wh});
            }
        }
        //find missing working days for missing keys
        for (Working_Days__c wd : [select id,Date__c,Performed_By_contact__c from Working_Days__c where id not in:wdBykey.values() and Performed_By_contact__c in:missingContacts and Date__c in:missingDates]){
            String key = wd.Performed_By_contact__c+';'+dateToStr(wd.Date__c);
            wdBykey.put(key, wd.id);
        }
        fixData(wdBykey, whsByKey, false);
    }
    public static void fixDataFromWorkingHours(List <Working_Hours__c> whs){

        Map <String, String> wdBykey = new Map <String, String>();
        Map <String, List<Working_Hours__c>> whsByKey = new Map <String, List<Working_Hours__c>>();
        Set <String> missingContacts = new Set <String>();
        Set <Date> missingDates = new Set <Date>();

        for(Working_Hours__c wh:whs){

            String key = wh.Performed_By_2__c+';'+dateToStr(wh.Date__c);
            
            if(whsByKey.containsKey(key))    whsByKey.get(key).add(wh);
            else{
                missingContacts.add(wh.Performed_By_2__c);
                missingDates.add(wh.Date__c);
                whsByKey.put(key, new List<Working_Hours__c>{wh});
            }
        }
        //find missing working days for missing keys
        for (Working_Days__c wd : [select id,Date__c,Performed_By_contact__c from Working_Days__c where Performed_By_contact__c in:missingContacts and Date__c in:missingDates]){
            String key = wd.Performed_By_contact__c+';'+dateToStr(wd.Date__c);
            wdBykey.put(key, wd.id);
        }
        fixData(wdBykey, whsByKey, true);
    }
    public static void fixData(Map <String, String> wdBykey,Map <String, List<Working_Hours__c>> whsByKey, Boolean isBefore){
        List <Working_Hours__c> whs4update = new List <Working_Hours__c>();
        for(String key:whsByKey.keyset()){
            if(wdBykey.containsKey(key)){
                for(Working_Hours__c wh:whsByKey.get(key)){
                    if(wh.Working_Day__c!=wdBykey.get(key)){
                        wh.Working_Day__c = wdBykey.get(key);
                        whs4update.add(wh);
                    }
                }
            } else {
                //no working day found
                for(Working_Hours__c wh:whsByKey.get(key)){
                    wh.Working_Day__c = null;
                    whs4update.add(wh);
                }
            }
        }
        if(whs4update.size()>0&&!isBefore) update whs4update;
    }
    public static String dateToStr(Date dat){
        return dat!=null?(String.valueof(dat.year())+'-'+String.valueof(dat.month())+'-'+String.valueof(dat.day())):'';
    }
}