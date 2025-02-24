trigger WorkingDayTrigger on Working_Days__c (before insert, before update,after insert, after update) {
    if(Trigger.isBefore){
        List<Working_Days__c> wDsThatNeedNewMonthlys = new List<Working_Days__c>();
        if(Trigger.isInsert ){
            for(Working_Days__c wd :  Trigger.new){
                wDsThatNeedNewMonthlys.add(wd);
                if(wd.Start__c!=null){
                    wd.Day__c = wd.Start__c.format('EEEE');
                }
            }
        }
        else if(Trigger.isUpdate){
            for(Id wDId : Trigger.newMap.keySet()){
                // if monthly changed || date || contact --> suspect!!!!!
                if(Trigger.oldMap.get(wDId).Monthly_Hours__c==null || Trigger.oldMap.get(wDId).Weekly_Hours__c==null||
                    Trigger.oldMap.get(wDId).Monthly_Hours__c != Trigger.newMap.get(wDId).Monthly_Hours__c || 
                    Trigger.oldMap.get(wDId).Weekly_Hours__c != Trigger.newMap.get(wDId).Weekly_Hours__c || 
                    Trigger.oldMap.get(wDId).Date__c != Trigger.newMap.get(wDId).Date__c ||
                    Trigger.oldMap.get(wDId).Start__c != Trigger.newMap.get(wDId).Start__c ||
                    Trigger.oldMap.get(wDId).Performed_By_contact__c != Trigger.newMap.get(wDId).Performed_By_contact__c ){
                        wDsThatNeedNewMonthlys.add(Trigger.newMap.get(wDId));
                        
                    }
                if(Trigger.newMap.get(wDId).Start__c!=null&&(Trigger.oldMap.get(wDId).Start__c != Trigger.newMap.get(wDId).Start__c||Trigger.newMap.get(wDId).Day__c==null)){
                    Trigger.newMap.get(wDId).Day__c = Trigger.newMap.get(wDId).Start__c.format('EEEE');
                }
            }
        }
        if(!wDsThatNeedNewMonthlys.isEmpty())        
            MonthlyController.attachAndDisattachMonthlysTo(wDsThatNeedNewMonthlys, 'Working_Days__c', true);
    } else {
        List<Working_Days__c> wDToUpdate = new List<Working_Days__c>();
        for (Working_days__c newWD : Trigger.new) { // filter working days list
            if(Trigger.isInsert ||
            newWD.Performed_By_contact__c != Trigger.oldMap.get(newWD.Id).Performed_By_contact__c || 
            newWD.Start__c != Trigger.oldMap.get(newWD.Id).Start__c){
                wDToUpdate.add(newWD);
            }
        }
        if(!wDToUpdate.isEmpty())
            ConAndDisWorkingHourToDay.fixDataFromWorkingDays(wDToUpdate); 
    }
}