@isTest (seealldata=true)
private class WorkingHourTest {
    
    @isTest 
    static public void attachHoursToMonthly(){

        
        String conId = [select id from Contact where name='Edan Badani' limit 1].id;
        String recTypeIdSalesforce = [select id from RecordType Where SobjectType='Working_Hours__c' and Name='Salesforce' limit 1].id;
        //Monthly_Hours__c m11, m10;

        Date oct = Date.newInstance(2021, 10, 01);
        Date nov = Date.newInstance(2021, 11, 01);
        oct = oct.addYears(2);
        nov = nov.addYears(2);
        String OuniqueKey = MonthlyController.initUniqueKeyFrom(conId, oct);
        String NuniqueKey = MonthlyController.initUniqueKeyFrom(conId, nov);
        List<Holidays__c> holidays = HolidaysCustomSettingWrapper.getRelevantHolidays(oct,nov);

        // create two monthly --> 10/11 & 11/11
        Monthly_Hours__c m10 = MonthlyController.createMonthly(conId, oct, null);
        Monthly_Hours__c m11 = MonthlyController.createMonthly(conId, nov, null);

        upsert new List<Monthly_Hours__c>{m11, m10} Key__c;


        Working_Hours__c wH1 = TestsUtil.createMeWH(recTypeIdSalesforce, conId, null, null, null, Date.newInstance(2021, 11, 11), 4, 'test', m11.Id, null);

        // insert monthly and working day
        insert wH1;

        // change working day date to exsisting date in monthly
        update new Working_Hours__c(Id=wH1.Id, Date__c = Date.newInstance(2021, 10, 17));
        upsert new Monthly_Teken__c(Date__c=nov,Teken__c=180,Key__c=String.valueof(nov)) Key__c;
    }
}