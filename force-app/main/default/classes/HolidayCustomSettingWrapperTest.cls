@isTest(seealldata=true)
public class HolidayCustomSettingWrapperTest {
    public static testMethod void tes() {
        Date startD = System.Today().addMonths(-3);
        Date endD = startD.addMonths(6);
        HolidaysCustomSettingWrapper.getRelevantHolidaysN(startD,endD);
        HolidaysCustomSettingWrapper.getRelevantWeeklies(startD,endD);
        HolidaysCustomSettingWrapper.getRelevantHolidays(startD,endD);
        HolidaysCustomSettingWrapper.getEarliestAndLatestDates(new Set<Date>{startD,endD});
    }
}