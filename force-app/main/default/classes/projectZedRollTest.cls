@isTest(seealldata=true)
public class projectZedRollTest{
    static testMethod void tes(){
    	update [select id from project__c limit 1];
    }
}