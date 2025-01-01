@isTest (seealldata=true)
private class WorkingDayTest {

    @isTest 
    static public void attachDayToMonthly(){

        // create two monthly --> 10/11 & 11/11
        String conId = [select id from Contact where name='Edan Badani' limit 1].id;

        Date oct = Date.newInstance(2021, 10, 01);
        Date nov = Date.newInstance(2021, 11, 01);
        oct = oct.addYears(2);
        nov = nov.addYears(2);
        String OuniqueKey = MonthlyController.initUniqueKeyFrom(conId, oct);
        String NuniqueKey = MonthlyController.initUniqueKeyFrom(conId, nov);
        List<Holidays__c> holidays = HolidaysCustomSettingWrapper.getRelevantHolidays(oct,nov);
        
        Monthly_Hours__c m10 = MonthlyController.createMonthly(conId, oct, null);
        Monthly_Hours__c m11 = MonthlyController.createMonthly(conId, nov, null);

        upsert new List<Monthly_Hours__c>{m11, m10} Key__c;
        Working_Days__c w1 = TestsUtil.createMeWD(conId, Datetime.newInstance(2021, 11, 17), 'Work', m11.Id, null);

        // insert monthly and working day
        insert w1;

        // change working day date to exsisting date in monthly

        update new Working_Days__c(Id=w1.Id, Start__c = Datetime.newInstance(2021, 10, 17));
        System.enqueueJob(new MonthlyController());
        m11.Sunday_end_time__c = Time.newInstance(17,0,0,0);
        update m11;
    }
}