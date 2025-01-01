@isTest(seealldata=true)
public class IssueZedRollTest{
static testMethod void tes(){
update [select id from Issue__c limit 1];
}
}