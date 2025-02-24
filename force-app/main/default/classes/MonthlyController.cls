/**
 * @description       : 
 * @author            : Lioz Elmalem
 * @group             : 
 * @last modified on  : 05-17-2022
 * @last modified by  : Lioz Elmalem
**/
public with sharing class MonthlyController implements Queueable{
    
    public void execute(QueueableContext qc){
        List <Working_Hours__c> whs = [select id,Date__c from Working_hours__c where weekly_hours__c=null Order by Date__c asc limit 500];
        List <Working_Days__c> wds = [select id,Date__c from Working_Days__c where weekly_hours__c=null Order by Date__c asc limit 500];
        if(whs.size()>0)    update whs;
        if(wds.size()>0)    update wds;
        if((whs.size()==500||wds.size()==500)&&!Test.isRunningTest())    ID jobID = System.enqueueJob(new MonthlyController());
    }
    public static Monthly_Hours__c createMonthly(String conId, Date newMDate, Map<Id, Map<Date,Monthly_Hours__c>> allMonsMap){
        // give basic values
        Monthly_Hours__c newM = new Monthly_Hours__c(
            Date__c = newMDate,
            Contact__c = conId,
            Key__c = initUniqueKeyFrom(conId, newMDate)
        );
        Monthly_Hours__c oldM = getDefaultValuseFromOld(conId, newMDate, 1, allMonsMap);
        // if can, give default extra values
        if(oldM!=null){
            newM = passOldDefaultValuse(oldM, newM);
        }
        return newM;
    }
    public static List<Weekly_Hours__c> createWeeklies(Monthly_Hours__c newM, Set <Date> datesFull, Set <Date> datesFullMuslims, Set <Date> halfDates, Set <Date> halfDatesMuslims, Map <String,Contact> contactsMap){
        List<Weekly_Hours__c> weeklies = new List<Weekly_Hours__c>();
        Datetime startD = Datetime.newInstance(newM.Date__c.year(),newM.Date__c.month(),1,0,0,0);
        Datetime endD = Datetime.newInstance(newM.Date__c.year(),newM.Date__c.month()+1,1,0,0,0);
        Date temp;
        while(startD.format('EEE')!='Sun'){
            startD = startD.addDays(1);
        }
        while(startD<endD){
            temp = startD.Date();
            String key = MonthlyController.initUniqueKeyFrom(newM.Contact__c, temp);
            weeklies.add(new Weekly_Hours__c(
                Monthly_Hours__c=newM.Id,
                Key__c=key,
                Start_Date__c=temp,
                Sunday_start_time__c=newM.Sunday_start_time__c,
                Sunday_end_time__c=newM.Sunday_end_time__c,
                Sunday_max_hours__c=maxHoursCheck(newM,temp,datesFull, datesFullMuslims, halfDates, halfDatesMuslims,contactsMap),
                Monday_start_time__c=newM.Monday_start_time__c,
                Monday_end_time__c=newM.Monday_end_time__c,
                Monday_max_hours__c=maxHoursCheck(newM,temp.addDays(1),datesFull, datesFullMuslims, halfDates, halfDatesMuslims,contactsMap),
                Tuesday_start_time__c=newM.Tuesday_start_time__c,
                Tuesday_end_time__c=newM.Tuesday_end_time__c,
                Tuesday_max_hours__c=maxHoursCheck(newM,temp.addDays(2),datesFull, datesFullMuslims, halfDates, halfDatesMuslims,contactsMap),
                Wednesday_start_time__c=newM.Wednesday_start_time__c,
                Wednesday_end_time__c=newM.Wednesday_end_time__c,
                Wednesday_max_hours__c=maxHoursCheck(newM,temp.addDays(3),datesFull, datesFullMuslims, halfDates, halfDatesMuslims,contactsMap),
                Thursday_start_time__c=newM.Thursday_start_time__c,
                Thursday_end_time__c=newM.Thursday_end_time__c,
                Thursday_max_hours__c=maxHoursCheck(newM,temp.addDays(4),datesFull, datesFullMuslims, halfDates, halfDatesMuslims,contactsMap),
                Friday_start_time__c=newM.Friday_start_time__c,
                Friday_end_time__c=newM.Friday_end_time__c,
                Friday_max_hours__c=maxHoursCheck(newM,temp.addDays(5),datesFull, datesFullMuslims, halfDates, halfDatesMuslims,contactsMap)
            ));
            startD = startD.addDays(7);
        }
        return weeklies;
    }
    public static Date sundayStartWeek(Date dat){
        Datetime temp = Datetime.newInstance(dat.year(),dat.month(),dat.day(),0,0,0);
        if(temp.format('EEE')=='Sun')   return dat;
        dat = dat.toStartOfWeek();
        temp = Datetime.newInstance(dat.year(),dat.month(),dat.day(),0,0,0);
        if(temp.format('EEE')=='Mon')   dat = dat.addDays(-1);
        return dat;
    }
    public static Map<Date,Planned_Time_Per_Week__c> createPlannedWeekliesBase(Scope_Item__c si){
        Map<Date,Planned_Time_Per_Week__c> weeklies = new Map<Date,Planned_Time_Per_Week__c>();
        Date realStartD = si.Start_Date__c;
        Date realEndD = si.End_Date__c;
        Date startD = sundayStartWeek(realStartD);
        Date endD = sundayStartWeek(realEndD);
        endD = endD.addDays(7);
        Date temp = startD;
        List <Date> sortedDates = new List<Date>();
        while(temp<endD){
            Decimal numOfDays = 5;
            if(temp<realStartD) {
                Integer delta = temp.daysBetween(realStartD);
                numOfDays = numOfDays - delta;
            }
            if(realEndD<temp.addDays(4)) {
                Integer delta = realEndD.daysBetween(temp.addDays(4));
                numOfDays = numOfDays - delta;
            }
            if(numOfDays>0) {
                sortedDates.add(temp);
            }
            temp = temp.addDays(7);
        }
        for(Integer i=0;i<sortedDates.size();i++){
            Planned_Time_Per_Week__c weekly = new Planned_Time_Per_Week__c(
                Start_Date__c=sortedDates[i],
                Scope_Item__c=si.id,
                Budget_QA__c=0,
                Budget_System_Architect__c=0,
                Budget_Developer__c=0,
                Budget_Implementation_Specialist__c=0,
                Budget_PM__c=0
            );
            weeklies.put(sortedDates[i],weekly);
        }
        return weeklies;
    }
    public static Map<Date,Planned_Time_Per_Week__c> createPlannedWeeklies(Scope_Item__c si, String scopeItemBudgetField, String plannedBudgetField, Boolean isInsert, Map<Date,Planned_Time_Per_Week__c> existingPlanned){
        Map<Date,Planned_Time_Per_Week__c> weeklies = new Map<Date,Planned_Time_Per_Week__c>();
        Date realStartD = si.Start_Date__c;
        Date realEndD = si.End_Date__c;
        Date startD = sundayStartWeek(realStartD);
        Date endD = sundayStartWeek(realEndD);
        endD = endD.addDays(7);
        Decimal totalBudget = (Decimal) si.get(scopeItemBudgetField) != null ? (Decimal) si.get(scopeItemBudgetField) : 0;
        Decimal totalDays = 0;
        Decimal jmps = 0.25;
        Date temp = !isInsert ? (realStartD < Date.today() ? sundayStartWeek(Date.today().addDays(7)) : startD) : startD;
        Map <Date,Decimal> numdaysByDate = new Map<Date,Decimal>();
        List <Date> sortedDates = new List<Date>();
        Date tempRM = startD;
        Decimal budgetRM = 0;
        while(tempRM<temp){
            if(existingPlanned.containsKey(tempRM)&&existingPlanned.get(tempRM).get(plannedBudgetField)!=null)
                budgetRM += (Decimal)   existingPlanned.get(tempRM).get(plannedBudgetField);
            tempRM = tempRM.addDays(7);
        }
        totalBudget = totalBudget - budgetRM;
        if(totalBudget<0)   throw new DMLException('Cannot remove budget for passed planned weeks');
        while(temp<endD){
            Decimal numOfDays = 5;
            if(temp<realStartD) {
                Integer delta = temp.daysBetween(realStartD);
                numOfDays = numOfDays - delta;
            }
            if(realEndD<temp.addDays(4)) {
                Integer delta = realEndD.daysBetween(temp.addDays(4));
                numOfDays = numOfDays - delta;
            }
            if(numOfDays>0) {
                numdaysByDate.put(temp, numOfDays);
                sortedDates.add(temp);
                totalDays += numOfDays;
            }
            temp = temp.addDays(7);
        }
        Decimal budgetPerDay = totalDays!=0?(totalBudget/totalDays).setScale(2):0;
        Decimal assignedHours = 0;
        for(Integer i=0;i<sortedDates.size();i++){
            Decimal curHours;
            if(i!=sortedDates.size()-1){
                curHours = (numdaysByDate.get(sortedDates[i])*budgetPerDay);
                Decimal curFloor = Math.floor(curHours);
                if(curFloor!=curHours){
                    if(curFloor+jmps>=curHours) curHours = curFloor+jmps;
                    else if(curFloor+(jmps*2)>=curHours) curHours = curFloor+(jmps*2);
                    else if(curFloor+(jmps*3)>=curHours) curHours = curFloor+(jmps*3);
                    else if(curFloor+(jmps*4)>=curHours) curHours = curFloor+(jmps*4);
                }
            } else {
                curHours = (totalBudget-assignedHours);
            }
            Planned_Time_Per_Week__c weekly = new Planned_Time_Per_Week__c(
                Start_Date__c=sortedDates[i],
                Scope_Item__c=si.id
            );
            weekly.put(plannedBudgetField, curHours);
            weeklies.put(sortedDates[i],weekly);
            assignedHours += curHours;
            if(curHours<=0&&i==sortedDates.size()-1){
                if (totalBudget == 0) {
                    weeklies.get(sortedDates[i]).put(plannedBudgetField, 0);
                }
                else {
                    weeklies.get(sortedDates[i]).put(plannedBudgetField, 0.5);
                    Decimal num = (curHours*(-1))+0.5;
                    Integer maxFix = i-1;
                    Decimal curFixAssign = 0;
                    Decimal perRowFix = (num/maxFix).setScale(2);
                    Decimal perRowFloor = Math.floor(perRowFix);
                    if(perRowFloor!=perRowFix){
                        if(perRowFloor+jmps>=perRowFix) perRowFix = perRowFloor+jmps;
                        else if(perRowFloor+(jmps*2)>=perRowFix) perRowFix = perRowFloor+(jmps*2);
                        else if(perRowFloor+(jmps*3)>=perRowFix) perRowFix = perRowFloor+(jmps*3);
                        else if(perRowFloor+(jmps*4)>=perRowFix) perRowFix = perRowFloor+(jmps*4);
                    }
                    for(integer j=maxFix;(j>=0&&curFixAssign<num);j--){
                        weeklies.get(sortedDates[j]).put(plannedBudgetField, (Decimal) weeklies.get(sortedDates[j]).get(plannedBudgetField) - perRowFix);
                        curFixAssign += perRowFix;
                    }
                }
            }
        }
        return weeklies;
    }
    public static Map<String,Map<Date,Planned_Time_Per_Week__c>> getPlannedWeeklies(Set<String> siids){
        Map<String,Map<Date,Planned_Time_Per_Week__c>> ptpwsByDatebyScopeid = new Map<String,Map<Date,Planned_Time_Per_Week__c>>();
        for(String sid:siids)
            ptpwsByDatebyScopeid.put(sid, new Map<Date,Planned_Time_Per_Week__c>());
        for(Planned_Time_Per_Week__c ptpw:[SELECT id,Start_Date__c,Scope_Item__c,Budget__c, Budget_QA__c, Budget_Developer__c, Budget_Implementation_Specialist__c, Budget_PM__c, Budget_System_Architect__c FROM Planned_Time_Per_Week__c WHERE Scope_Item__c IN: siids]) {
            ptpwsByDatebyScopeid.get(ptpw.Scope_Item__c).put(ptpw.Start_Date__c, ptpw);
        }
        return ptpwsByDatebyScopeid;
    }
    public static Decimal maxHoursCheck(Monthly_Hours__c newM,Date dat,Set <Date> datesFull, Set <Date> datesFullMuslims, Set <Date> halfDates, Set <Date> halfDatesMuslims, Map <String,Contact> contactsMap){
        Decimal fullHours = 9;
        Decimal hoursMus = fullHours;
        Decimal hoursJew = fullHours;
        if(contactsMap!=null&&contactsMap.containsKey(newM.Contact__c)&&contactsMap.get(newM.Contact__c).isMuslim__c==true){
            if(datesFullMuslims.contains(dat)){
                hoursMus = 0; 
            } else if(halfDatesMuslims.contains(dat)){
                hoursMus = fullHours/2.0;
            }
        }
        if(datesFull.contains(dat)){
            hoursJew = 0; 
        } else if(halfDates.contains(dat)){
            hoursJew = fullHours/2.0;
        }
        return hoursJew<hoursMus?hoursJew:hoursMus;
    }

    public static Map<Id, Map <Date, Monthly_Hours__c>> makeMonthlysToMap(List<Monthly_Hours__c> monthlys){
        Map<Id, Map <Date, Monthly_Hours__c>> resM = new  Map<Id, Map <Date, Monthly_Hours__c>>();
        for(Monthly_Hours__c curM : monthlys){
            if(!resM.containsKey(curM.Contact__c))  resM.put(curM.Contact__c, new Map<Date, Monthly_Hours__c>());
            resM.get(curM.Contact__c).put(curM.Date__c, curM);
        }
        return resM;
    }

    private static Monthly_Hours__c passOldDefaultValuse(Monthly_Hours__c oldM, Monthly_Hours__c newM){
        newM.Sunday_start_time__c=oldM.Sunday_start_time__c;
        newM.Sunday_end_time__c=oldM.Sunday_end_time__c;
        newM.Monday_start_time__c=oldM.Monday_start_time__c;
        newM.Monday_end_time__c=oldM.Monday_end_time__c;
        newM.Tuesday_start_time__c=oldM.Tuesday_start_time__c;
        newM.Tuesday_end_time__c=oldM.Tuesday_end_time__c;
        newM.Wednesday_start_time__c=oldM.Wednesday_start_time__c;
        newM.Wednesday_end_time__c=oldM.Wednesday_end_time__c;
        newM.Thursday_start_time__c=oldM.Thursday_start_time__c;
        newM.Thursday_end_time__c=oldM.Thursday_end_time__c;
        newM.Friday_start_time__c=oldM.Friday_start_time__c;
        newM.Friday_end_time__c=oldM.Friday_end_time__c;
        return newM;
    }

    public static Boolean valuesChanged(Monthly_Hours__c oldM, Monthly_Hours__c newM){
        return newM.Sunday_start_time__c!=oldM.Sunday_start_time__c||
        newM.Sunday_end_time__c!=oldM.Sunday_end_time__c||
        newM.Monday_start_time__c!=oldM.Monday_start_time__c||
        newM.Monday_end_time__c!=oldM.Monday_end_time__c||
        newM.Tuesday_start_time__c!=oldM.Tuesday_start_time__c||
        newM.Tuesday_end_time__c!=oldM.Tuesday_end_time__c||
        newM.Wednesday_start_time__c!=oldM.Wednesday_start_time__c||
        newM.Wednesday_end_time__c!=oldM.Wednesday_end_time__c||
        newM.Thursday_start_time__c!=oldM.Thursday_start_time__c||
        newM.Thursday_end_time__c!=oldM.Thursday_end_time__c||
        newM.Friday_start_time__c!=oldM.Friday_start_time__c||
        newM.Friday_end_time__c!=oldM.Friday_end_time__c;
    }

    private static Monthly_Hours__c getDefaultValuseFromOld(String curConId, Date curDate, Integer old, Map<Id, Map <Date, Monthly_Hours__c>> allMonsMap){
        if(allMonsMap!=null&&allMonsMap.containsKey(curConId)){
            Date oldDate = curDate.addMonths((-1)*old);
            if(allMonsMap.get(curConId).containsKey(oldDate))   return allMonsMap.get(curConId).get(oldDate);
            if(old==6)  return null;
            else return getDefaultValuseFromOld(curConId, curDate, old+1, allMonsMap);
        }
        return null;
    }

    private static string getNumForDate(Integer n){
        return n < 10 ? '0'+String.valueOf(n) : String.valueOf(n);
    }

    public static Map<String, Monthly_Hours__c> getMonthByKey(Map<Id, Map <Date, Monthly_Hours__c>> allMonsMap){
        Map<String, Monthly_Hours__c> resM = new Map<String,Monthly_Hours__c>();
        String uniqueKey;
        for(String k:allMonsMap.keySet()){
            for(Date k2:allMonsMap.get(k).keySet()){
                uniqueKey = MonthlyController.initUniqueKeyFrom(k,k2);
                resM.put(uniqueKey, allMonsMap.get(k).get(k2));
            }
        }
        return resM;       
    }

    public static List<Monthly_Hours__c> getRelevantMonthlys(Set<Id> conIds){
        String SunTime , monTime, tueTime, wendTime, thurTime, friTime, allWeekFields, moreDefFields, mustFields; 
        mustFields = 'Name, Date__c, Contact__c, User__c, ';
        SunTime = 'Sunday_end_time__c, Sunday_start_time__c, '; 
        monTime = 'Monday_end_time__c, Monday_start_time__c, ';
        tueTime = 'Tuesday_end_time__c, Tuesday_start_time__c, ';
        wendTime = 'Wednesday_end_time__c, Wednesday_start_time__c, ';
        thurTime = 'Thursday_end_time__c, Thursday_start_time__c, ';
        friTime = 'Friday_end_time__c, Friday_start_time__c, ';
        allWeekFields = SunTime + monTime + tueTime + wendTime + thurTime + friTime;
        moreDefFields = '(select Id,'+SunTime + monTime + tueTime + wendTime + thurTime + friTime+'Start_Date__c,End_Date__c from Weekly_Hours__r Order by CreatedDate, Start_Date__c)';
        return Database.query('SELECT '+mustFields+allWeekFields+moreDefFields+' FROM Monthly_Hours__c WHERE Contact__c IN : conIds Order by Contact__c,Date__c desc');       
    }

    public static List<Weekly_Hours__c> getRelevantWeekliesDB(Set<String> mhIds){
        String SunTime , monTime, tueTime, wendTime, thurTime, friTime, allWeekFields, moreDefFields, mustFields; 
        SunTime = 'Sunday_end_time__c, Sunday_start_time__c, '; 
        monTime = 'Monday_end_time__c, Monday_start_time__c, ';
        tueTime = 'Tuesday_end_time__c, Tuesday_start_time__c, ';
        wendTime = 'Wednesday_end_time__c, Wednesday_start_time__c, ';
        thurTime = 'Thursday_end_time__c, Thursday_start_time__c, ';
        friTime = 'Friday_end_time__c, Friday_start_time__c, ';
        return Database.query('select Id,Monthly_Hours__c,'+SunTime + monTime + tueTime + wendTime + thurTime + friTime+'Start_Date__c from Weekly_Hours__c Where Monthly_Hours__c in:mhIds Order by Monthly_Hours__c,Start_Date__c');       
    }

    public static String initUniqueKeyFrom(String curId, Date curDate){
        return curId + ' ' + String.valueOf(curDate.year())+'-'+getNumForDate(curDate.month())+'-'+getNumForDate(curDate.day()); 
    }

    public static String initOldUniqueKeyFrom(String uniqueKey){
        String [] spl = uniqueKey.split(' ');
        String [] spl2 = spl[1].split('-');
        Date dat = Date.newInstance(Integer.valueof(spl2[0]),Integer.valueof(spl2[1]),Integer.valueof(spl2[2]));
        dat = dat.addMonths(-1);
        return initUniqueKeyFrom(spl[0],dat); 
    }

    public static void attachRecsToMs(List<Sobject> recs, Map<Id, Map <Date, Monthly_Hours__c>> allMonsMap, Map<String, Monthly_Hours__c> toInsert, String conField, String dateField, Map<String, Working_Team_Resource__c> idToWTRs, Map <String,Contact> contactsMap){
        Monthly_Hours__c curM;
        Weekly_Hours__c curW;
        Id curConId;
        Date curStartMonDate;
        Date oldStartMonDate;
        String uniqueKey;
        String oldUniqueKey;
        Map <String,Monthly_Hours__c> monts4up = new Map <String,Monthly_Hours__c>();
        for(Sobject rec : recs){
            // start data for cur round
            if(idToWTRs!=null)  curConId = idToWTRs.get(((String)rec.get(conField))).Contact__c;
            else                curConId = (String) rec.get(conField);
            curStartMonDate = ((Date) rec.get(dateField)).toStartOfMonth();
            oldStartMonDate = curStartMonDate.addMonths(-1);
            uniqueKey = MonthlyController.initUniqueKeyFrom(curConId, curStartMonDate);
            oldUniqueKey = MonthlyController.initUniqueKeyFrom(curConId, oldStartMonDate);
            if(!toInsert.containsKey(uniqueKey)){
                if(!allMonsMap.containsKey(curConId)||!allMonsMap.get(curConId).containsKey(curStartMonDate)){// Didn't find fitting monthly, create & attach
                    curM = MonthlyController.createMonthly(curConId, curStartMonDate, allMonsMap);
                    toInsert.put(uniqueKey, curM);
                } else if(allMonsMap.get(curConId).get(curStartMonDate).User__c==null){
                    monts4up.put(allMonsMap.get(curConId).get(curStartMonDate).id, allMonsMap.get(curConId).get(curStartMonDate));
                }
            }
            if(!toInsert.containsKey(oldUniqueKey)){
                if(!allMonsMap.containsKey(curConId)||!allMonsMap.get(curConId).containsKey(oldStartMonDate)){ 
                    Monthly_Hours__c oldCurM = MonthlyController.createMonthly(curConId, oldStartMonDate, allMonsMap);
                    toInsert.put(oldUniqueKey, oldCurM);
                } else if(allMonsMap.get(curConId).get(oldStartMonDate).User__c==null){
                    monts4up.put(allMonsMap.get(curConId).get(oldStartMonDate).id, allMonsMap.get(curConId).get(oldStartMonDate));
                }
            }
        }
        if(monts4up.size()>0)   update monts4up.values();
    }

    public static void attachAndDisattachRecsToMonthlys(Map<Id, Map <Date, Monthly_Hours__c>> allMonsMap, List<Sobject> recs, Boolean isFromTrigger, String conField, String dateField, Map<String, Working_Team_Resource__c> idToWTRs, Map <String,Contact> contactsMap){
        Map<String, List<Sobject>> sobjMap = initMapUniqueKeyToRecsFrom(recs,conField,dateField,idToWTRs);
        Map<String, Monthly_Hours__c> toInsert = new Map<String, Monthly_Hours__c>();
        Monthly_Hours__c curM;
        Weekly_Hours__c curW;
        List <Weekly_Hours__c> newWs;
        List <Weekly_Hours__c> oldWs;
        attachRecsToMs(recs, allMonsMap, toInsert, conField, dateField, idToWTRs, contactsMap);
        // give monthlys ids
        if(!toInsert.keySet().isEmpty()){
            insert toInsert.values();
        }
        allMonsMap = MonthlyController.makeMonthlysToMap(MonthlyController.getRelevantMonthlys(allMonsMap.keySet()));
        Map <String, Monthly_Hours__c> monsByKey = MonthlyController.getMonthByKey(allMonsMap);
        // update needed lookups
        String oldUniqueKey;
        for(String curUniqueKey : sobjMap.keySet()){
            curM = monsByKey.get(curUniqueKey);
            oldUniqueKey = MonthlyController.initOldUniqueKeyFrom(curUniqueKey);
            newWs = monsByKey.get(curUniqueKey).Weekly_Hours__r;
            oldWs = monsByKey.get(oldUniqueKey).Weekly_Hours__r;
            for(Sobject rec:sobjMap.get(curUniqueKey)){
                curW = getRelevantWeekly(rec,oldWs.size()>0?oldWs[oldWs.size()-1]:null,newWs);
                if(idToWTRs==null)  rec.put('Monthly_Hours__c',curM.Id);
                if(curW!=null)  rec.put('Weekly_Hours__c',curW.Id);
            }
        }
        if(!isFromTrigger)
            update recs;
    }

    public static Map<String, List<Sobject>> initMapUniqueKeyToRecsFrom(List<Sobject> recs, String conField, String dateField, Map<String, Working_Team_Resource__c> idToWTRs){
        Map<String, List<Sobject>> res = new Map<String, List<Sobject>>();
        String curKey, conId;
        Date curDate;
        for(Sobject rec : recs){
            if(idToWTRs!=null)  conId = idToWTRs.get(((String)rec.get(conField))).Contact__c;
            else                conId = (String) rec.get(conField);
            curDate = ((Date) rec.get(dateField)).toStartOfMonth();
            curKey = MonthlyController.initUniqueKeyFrom(conId, curDate);
            if(!res.containsKey(curKey))    res.put(curKey,new List<Sobject>());
            res.get(curKey).add(rec);
        }
        return res;
    }

    public static void attachAndDisattachMonthlysTo(List<Sobject> recs, String type, Boolean isFromTrigger){
        Set<Id> conIds = new Set<Id>();
        Map<Id, Map <Date, Monthly_Hours__c>> allMonsMap = new Map<Id, Map <Date, Monthly_Hours__c>>();
        Map<String, Working_Team_Resource__c> idToWTRs = null;
        String conField;
        String dateField = 'Date__c';
        if(type=='Working_Days__c'){
            conField = 'Performed_By_contact__c';
        } else if(type=='Working_Hours__c'){
            conField = 'Performed_By_2__c';
        } else if(type=='Resource_Planning_Per_Week__c'){
            conField = 'Working_Team_Resource__c';
            idToWTRs = initIdToWTR(recs);
            conIds = getConIdsFrom(idToWTRs.values());
        }
        // start sets for filters
        for(Sobject rec : recs){
            if(type!='Resource_Planning_Per_Week__c')   conIds.add((String) rec.get(conField));
        }
        Map<String, Contact> contactsMap = new Map<String, Contact>([select id,IsMuslim__c,Name from Contact where id in:conIds]);
        // get all relavent monthly
        allMonsMap = MonthlyController.makeMonthlysToMap(MonthlyController.getRelevantMonthlys(conIds));
        //  Make monthly maps:
        //<conId, <dd/mm/yyyy, MH>
        // attach
        attachAndDisattachRecsToMonthlys(allMonsMap, recs, isFromTrigger, conField, dateField, idToWTRs, contactsMap); 
    }

    private static Map<String, Working_Team_Resource__c> initIdToWTR(List<Resource_Planning_Per_Week__c> ress){
        Set<String> filter = new Set<String>();
        Map<String, Working_Team_Resource__c> resM = new Map<String, Working_Team_Resource__c>();
        List<Working_Team_Resource__c> wTRs = new List<Working_Team_Resource__c>();
        for(Resource_Planning_Per_Week__c curR : ress)
            filter.add(curR.Working_Team_Resource__c);
        wTRs = [SELECT Id, Contact__c FROM Working_Team_Resource__c WHERE Id IN: filter];
        for(Working_Team_Resource__c cur : wTRs)
            resM.put(cur.Id, cur);
        return resM;
    }

    public static Set<Id> getConIdsFrom(List<Working_Team_Resource__c> wTRs){
        Set<Id> resSet = new Set<Id>();
        for(Working_Team_Resource__c curW : wTRs)
            resSet.add(curW.Contact__c);
        return resSet;
    }

    public static Weekly_Hours__c getRelevantWeekly(Sobject rec, Weekly_Hours__c lastMonthLastWeek, List<Weekly_Hours__c> weeklies){
        if(lastMonthLastWeek!=null&&lastMonthLastWeek.Start_Date__c.Month()!=((Date)rec.get('Date__c')).Month()&&lastMonthLastWeek.Start_Date__c<=((Date)rec.get('Date__c'))&&(lastMonthLastWeek.Start_Date__c.addDays(7))>((Date)rec.get('Date__c'))){
            return lastMonthLastWeek;
        }
        for(Weekly_Hours__c weekly:weeklies){
            if(weekly.Start_Date__c<=((Date)rec.get('Date__c'))&&(weekly.Start_Date__c.addDays(7))>((Date)rec.get('Date__c'))){
                return weekly;
            }
        }
        return null;
    }
}