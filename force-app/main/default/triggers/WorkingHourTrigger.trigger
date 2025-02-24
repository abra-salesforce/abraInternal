trigger WorkingHourTrigger on Working_Hours__c (before insert, before update) {

    String conId = currentContact.getContact();

    for(Working_Hours__c wh:Trigger.new){

        if(wh.Performed_By_2__c == null){

            if(conId!=null)     wh.Performed_By_2__c = conId;
            else                wh.addError('Performed by not found');
        }
    }
    
    List<Working_Hours__c> wHsThatNeedNewMonthlys = new List<Working_Hours__c>();
    List<Working_Hours__c> workingHours4attach = new List <Working_Hours__c>();
    List<Working_Hours__c> workingHours4planned = new List <Working_Hours__c>();

    if(Trigger.isInsert ){
    
        for(Working_Hours__c wH :  Trigger.new){
    
            if(wH.Date__c == null && wH.Start__c !=null) // if working hour of "IT"
                wH.Date__c = wH.Start__c.date();
            workingHours4attach.add(wH);
            wHsThatNeedNewMonthlys.add(wH);
            if(wH.Scope_Item__c!=null)  workingHours4planned.add(wH);
        }
    }    
    else if(Trigger.isUpdate){    
        for(Id wHId : Trigger.newMap.keySet()){
    
            if(Trigger.newMap.get(wHId).Performed_By_2__c != Trigger.oldMap.get(wHId).Performed_By_2__c || 
                Trigger.newMap.get(wHId).Date__c != Trigger.oldMap.get(wHId).Date__c){
                workingHours4attach.add(Trigger.newMap.get(wHId));
                if(Trigger.newMap.get(wHId).Scope_Item__c!=null)  workingHours4planned.add(Trigger.newMap.get(wHId));
            }
    
            Boolean isIT = false;
            // if it & month changed
            if(Trigger.oldMap.get(wHId).Start__c != Trigger.newMap.get(wHId).Start__c){
                Trigger.newMap.get(wHId).Date__c = Trigger.newMap.get(wHId).Start__c.date();
                isIT = true;
            }
            // if: (monthly changed || date of month || contact) --> suspect!!!!!
            if(Trigger.oldMap.get(wHId).Monthly_Hours__c==null || Trigger.oldMap.get(wHId).Weekly_Hours__c==null||
                Trigger.oldMap.get(wHId).Monthly_Hours__c != Trigger.newMap.get(wHId).Monthly_Hours__c || 
                Trigger.oldMap.get(wHId).Weekly_Hours__c != Trigger.newMap.get(wHId).Weekly_Hours__c || 
                Trigger.oldMap.get(wHId).Date__c != Trigger.newMap.get(wHId).Date__c ||
                Trigger.oldMap.get(wHId).Performed_By_2__c != Trigger.newMap.get(wHId).Performed_By_2__c ||
                isIT){
                wHsThatNeedNewMonthlys.add(Trigger.newMap.get(wHId));
            }
        }
    }

    if(!workingHours4attach.isEmpty())   
        ConAndDisWorkingHourToDay.fixDataFromWorkingHours(workingHours4attach);
    if(!wHsThatNeedNewMonthlys.isEmpty())        
        MonthlyController.attachAndDisattachMonthlysTo(wHsThatNeedNewMonthlys, 'Working_Hours__c', true);
    if(!workingHours4planned.isEmpty()) {
        Set <String> scopeids = new Set<String>();
        for(Working_Hours__c wh:workingHours4planned)   scopeids.add(wh.Scope_Item__c);
        Map <String,Scope_Item__c> scopes = new Map <String,Scope_Item__c>([select id,(select Id,Start_Date__c from Planned_Time_Per_Weeks__r) from Scope_Item__c where Id in: scopeids]);
        for(Working_Hours__c wh:workingHours4planned){
            wh.Planned_Time_Per_Week__c = null;
            if(scopes.containsKey(wh.Scope_Item__c)){
                Date startW = MonthlyController.sundayStartWeek(wh.Date__c);
                for(Planned_Time_Per_Week__c pl:scopes.get(wh.Scope_Item__c).Planned_Time_Per_Weeks__r){
                    if(pl.Start_Date__c == startW){
                        wh.Planned_Time_Per_Week__c = pl.id;
                        break;
                    }
                }
            }
        }
    }
}