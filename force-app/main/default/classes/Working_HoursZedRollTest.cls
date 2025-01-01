@isTest(seealldata=true)
public class Working_HoursZedRollTest{
static testMethod void tes(){
update [select id from Working_Hours__c limit 1];
}
}