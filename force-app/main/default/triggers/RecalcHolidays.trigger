/**
 * @ Author: abra - Edan Badani (ZedXagE)
 * @ Create Time: 2022-11-03 15:32:37
 * @ Modified by: Edan Badani (ZedXagE)
 * @ Modified time: 2023-02-09 20:22:31
 * @ Description:
 */

trigger RecalcHolidays on Holiday__c (after insert,after update,before delete,after undelete) {
    List <Holiday__c> holis = new List <Holiday__c>();
    Set <String> deletedIds = new Set <String>();
    if(Trigger.isDelete)    holis = Trigger.old;
    else                    holis = Trigger.new;
    Set <Date> holidates = new Set <Date>();
    Date latestDate = null;
    Date earliestDate = null;
    Set <Date> datesFull = new Set <Date>();
    Set <Date> datesFullMuslims = new Set <Date>();
    Set <Date> halfDates = new Set <Date>();
    Set <Date> halfDatesMuslims = new Set <Date>();
    for(Holiday__c holi:holis) {
        holidates.add(holi.Date__c);
        if(Trigger.isDelete) {
            deletedIds.add(holi.Id);
        }
    }
    List <Date> earliestAndLatestDates = HolidaysCustomSettingWrapper.getEarliestAndLatestDates(holidates);
    earliestDate = earliestAndLatestDates[0];
    latestDate = earliestAndLatestDates[1];
    holis = [select Date__c, Half_Day__c, Muslim_Holiday__c from Holiday__c where Date__c>= :earliestDate and Date__c<= :latestDate and id not in:deletedIds];
    HolidaysCustomSettingWrapper.initHolidays(holis, datesFull, datesFullMuslims, halfDates, halfDatesMuslims);
    List <Weekly_Hours__c> weeks = HolidaysCustomSettingWrapper.getRelevantWeeklies(earliestDate,latestDate);
    Date temp = null;
    Datetime tempDay = null;
    Decimal fullHours = 9;
    for(Weekly_Hours__c week:weeks){
        temp = week.Start_Date__c;
        tempDay = Datetime.newInstance(temp.year(), temp.month(), temp.day(), 0, 0, 0);
        while(temp<=week.End_Date__c){
            String dayName = tempDay.format('EEEE');
            if(dayName!='Saturday'){
                week.put(dayName+'_max_hours__c',fullHours);
                if(week.Monthly_Hours__r.Contact__r.isMuslim__c==true){
                    if(datesFullMuslims.contains(temp)){
                        week.put(dayName+'_max_hours__c',0);
                    } else if(halfDatesMuslims.contains(temp)){
                        week.put(dayName+'_max_hours__c',fullHours/2);
                    }
                }
                if(datesFull.contains(temp)){
                    week.put(dayName+'_max_hours__c',0);
                } else if(halfDates.contains(temp)){
                    week.put(dayName+'_max_hours__c',fullHours/2);
                }
            }
            temp = temp.addDays(1);
            tempDay = Datetime.newInstance(temp.year(), temp.month(), temp.day(), 0, 0, 0);
        }
    }
    update weeks;
}