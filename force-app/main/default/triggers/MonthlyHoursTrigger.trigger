trigger MonthlyHoursTrigger on Monthly_Hours__c (before insert, before update, after insert, after update) {
    Set <Id> conIds = new Set<Id>();
    for(Monthly_Hours__c mh:Trigger.new){
        conIds.add(mh.Contact__c);
    }
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            Map <Id, Map <Date,Monthly_Hours__c>> allMonsMap = MonthlyController.makeMonthlysToMap(MonthlyController.getRelevantMonthlys(conIds));
            //gen Key and extra
            for(Monthly_Hours__c mh:Trigger.new){
                mh.Weekly_Hours_extra__c=null;
                mh.Key__c = MonthlyController.initUniqueKeyFrom(mh.Contact__c, mh.Date__c);
                Date lastDat = mh.Date__c.addMonths(-1);
                if(allMonsMap.containsKey(mh.Contact__c)&&allMonsMap.get(mh.Contact__c).containsKey(lastDat)&&allMonsMap.containsKey(mh.Contact__c)&&allMonsMap.get(mh.Contact__c).get(lastDat).Weekly_Hours__r.size()>0){
                    Weekly_Hours__c lastWeek = allMonsMap.get(mh.Contact__c).get(lastDat).Weekly_Hours__r[allMonsMap.get(mh.Contact__c).get(lastDat).Weekly_Hours__r.size()-1];
                    if(lastWeek.Start_Date__c.addDays(6).Month()!=lastWeek.Start_Date__c.Month()){
                        mh.Weekly_Hours_extra__c=lastWeek.Id;
                    }
                }
            }
        }
        Map<String, Contact> contactsMap = new Map<String, Contact>([select id,Name,isMuslim__c from Contact where id in:conIds]);
        
        //Assign User
        Map<String,String> contIdByName = new Map<String,String>();
        Map<String,User> userByCon = new Map<String,User>();
        for(Contact c:contactsMap.values())  contIdByName.put(c.Name, c.Id);
        for(User u:[select id,Name,isActive from User where Name in:contIdByName.keySet()])
            if(contIdByName.containsKey(u.Name))
                userByCon.put(contIdByName.get(u.Name),u);
        Set <Date> dates4teken = new Set<Date>();
        for(Monthly_Hours__c mh:Trigger.new){
            if(mh.User__c==null)
                mh.User__c = userByCon.containsKey(mh.Contact__c)?userByCon.get(mh.Contact__c).id:null;
            if(mh.User__c!=null&&mh.Ownerid!=mh.User__c&&userByCon.containsKey(mh.Contact__c)&&userByCon.get(mh.Contact__c).isActive==true)
                mh.Ownerid = mh.User__c;
            if(mh.Monthly_Teken__c==null)
                dates4teken.add(mh.Date__c);
        }
        if(dates4teken.size()>0){
            //need fix teken
            Map<Date, String> monthlyTekes = new Map<Date, String>();
            for(Monthly_Teken__c mt:[select id,Date__c from Monthly_Teken__c Where Date__c in: dates4teken]) monthlyTekes.put(mt.Date__c, mt.id);
            for(Monthly_Hours__c mh:Trigger.new){
                if(mh.Monthly_Teken__c==null&&monthlyTekes.containsKey(mh.Date__c))
                    mh.Monthly_Teken__c = monthlyTekes.get(mh.Date__c);
            }
        }
    } else {
        //insert or update weeklies
        if(Trigger.isInsert){
            Set<Date> wDsDates =  new Set<Date>();
            Date earliestDate, latestDate;
            for(Monthly_Hours__c mh:Trigger.new){
                wDsDates.add(mh.Date__c);
            }
            List <Date> earliestAndLatestDates = HolidaysCustomSettingWrapper.getEarliestAndLatestDates(wDsDates);
            earliestDate = earliestAndLatestDates[0];
            latestDate = earliestAndLatestDates[1];
            List<Holiday__c> holidays = HolidaysCustomSettingWrapper.getRelevantHolidaysN(earliestDate, latestDate);
            Set <Date> datesFull = new Set<Date>();
            Set <Date> datesFullMuslims = new Set<Date>();
            Set <Date> halfDates = new Set<Date>();
            Set <Date> halfDatesMuslims = new Set<Date>();
            HolidaysCustomSettingWrapper.initHolidays(holidays, datesFull, datesFullMuslims, halfDates, halfDatesMuslims);
            Map<String, List<Weekly_Hours__c>> toInsertWeeklies = new Map<String, List<Weekly_Hours__c>>();
            Map<String, Contact> contactsMap = new Map<String, Contact>([select id,Name,isMuslim__c from Contact where id in:conIds]);
            for(Monthly_Hours__c mh:Trigger.new){
                toInsertWeeklies.put(MonthlyController.initUniqueKeyFrom(mh.Contact__c, mh.Date__c), MonthlyController.createWeeklies(mh, datesFull, datesFullMuslims, halfDates, halfDatesMuslims, contactsMap));
            }
            List <Weekly_Hours__c> weeklies4ins = new List<Weekly_Hours__c>();
            for(String k:toInsertWeeklies.keySet()){
                weeklies4ins.addAll(toInsertWeeklies.get(k));
            }
            insert weeklies4ins;
        } else if(Trigger.isUpdate){
            //update all weeklies
            Map <String,Monthly_Hours__c> monts4up = new Map<String,Monthly_Hours__c>();
            for(Monthly_Hours__c mh:Trigger.new){
                if(MonthlyController.valuesChanged(Trigger.oldMap.get(mh.Id),mh)||Test.isRunningTest())
                    monts4up.put(mh.id,mh);
            }
            if(monts4up.size()>0){
                List <Weekly_Hours__c> wks = MonthlyController.getRelevantWeekliesDB(monts4up.keySet());
                for(Weekly_Hours__c wk:wks){
                    Monthly_Hours__c mh = monts4up.get(wk.Monthly_Hours__c);
                    wk.Sunday_start_time__c=mh.Sunday_start_time__c;
                    wk.Sunday_end_time__c=mh.Sunday_end_time__c;
                    wk.Monday_start_time__c=mh.Monday_start_time__c;
                    wk.Monday_end_time__c=mh.Monday_end_time__c;
                    wk.Tuesday_start_time__c=mh.Tuesday_start_time__c;
                    wk.Tuesday_end_time__c=mh.Tuesday_end_time__c;
                    wk.Wednesday_start_time__c=mh.Wednesday_start_time__c;
                    wk.Wednesday_end_time__c=mh.Wednesday_end_time__c;
                    wk.Thursday_start_time__c=mh.Thursday_start_time__c;
                    wk.Thursday_end_time__c=mh.Thursday_end_time__c;
                    wk.Friday_start_time__c=mh.Friday_start_time__c;
                    wk.Friday_end_time__c=mh.Friday_end_time__c;
                }
                update wks;
            }
        }
    }
}