/**
 * @ Author: abra - Edan Badani (ZedXagE)
 * @ Create Time: 2021-12-20 17:02:07
 * @ Modified by: Edan Badani (ZedXagE)
 * @ Modified time: 2023-02-09 20:10:30
 * @ Description:
 */

public without sharing class HolidaysCustomSettingWrapper {

    // get relevant holidays
    public static List<Holiday__c> getRelevantHolidaysN(Date earliestDate, Date latestDate){
        List<Holiday__c> res = new List<Holiday__c>();
        // get holidays where dates between dates given
        if(earliestDate != null && latestDate != null)
            res = [SELECT Name, Date__c, Half_Day__c, Muslim_Holiday__c FROM Holiday__c WHERE Date__c >=: earliestDate AND Date__c <=: latestDate ORDER BY Date__c];

        return res;
    }
    public static List<Weekly_Hours__c> getRelevantWeeklies(Date earliestDate, Date latestDate){
        List<Weekly_Hours__c> res = new List<Weekly_Hours__c>();
        // get holidays where dates between dates given
        if(earliestDate != null && latestDate != null)
            res = [SELECT Id, Start_Date__c, End_Date__c,Monthly_Hours__r.Contact__r.isMuslim__c FROM Weekly_Hours__c WHERE End_Date__c >=: earliestDate AND Start_Date__c <=: latestDate ORDER BY Start_Date__c];

        return res;
    }
    public static void initHolidays(List<Holiday__c> holidays, Set <Date> datesFull, Set <Date> datesFullMuslims, Set <Date> halfDates, Set <Date> halfDatesMuslims){
        for(Holiday__c curHoli : holidays){
            if(curHoli.Half_Day__c){if(curHoli.Muslim_Holiday__c) halfDatesMuslims.add(curHoli.Date__c);else halfDates.add(curHoli.Date__c);} else {if(curHoli.Muslim_Holiday__c) datesFullMuslims.add(curHoli.Date__c);else datesFull.add(curHoli.Date__c);}
        }
    }

    public static List<Date> getEarliestAndLatestDates(Set<Date> dates){
        List<Date> dList = new List<Date>(dates);
        dlist.sort();
        List<Date> res = new List <Date>{dlist[0].addMonths(-1),dlist[dlist.size()-1].addMonths(1)};
        return res;
    }

    //old version
    public static List<Holidays__c> getRelevantHolidays(Date earliestDate, Date latestDate){	
        List<Holidays__c> res = new List<Holidays__c>();	
        // get holidays where dates between dates given	
        if(earliestDate != null && latestDate != null)	
            res = [SELECT Name, Date__c, IsHalf__c, isMuslim__c FROM Holidays__c WHERE Date__c >=: earliestDate AND Date__c <=: latestDate ORDER BY Date__c];	
        return res;	
    }	
    public static void initHolidays(List<Holidays__c> holidays, Set <Date> datesFull, Set <Date> datesFullMuslims, Set <Date> halfDates, Set <Date> halfDatesMuslims){	
        for(Holidays__c curHoli : holidays){if(curHoli.IsHalf__c){if(curHoli.IsMuslim__c) halfDatesMuslims.add(curHoli.Date__c);else halfDates.add(curHoli.Date__c);} else {if(curHoli.IsMuslim__c) datesFullMuslims.add(curHoli.Date__c);else datesFull.add(curHoli.Date__c);}	}	
    }

}