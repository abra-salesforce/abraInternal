@isTest(seealldata=true)
public with sharing class CallAsyncNavQueTest {
    @IsTest
public static void tes(){
        Test.startTest();
        new AsyncNavIntegrationSchedulable().execute(null);
        new AsyncNavIntegrationQueueable(null,null).execute(null);
        Test.stopTest();
    }
    @IsTest
public static void tes1(){
        Test.startTest();
        Working_Hours__c wh = [select id,Nav_Id__c,createdDate from Working_Hours__c where Nav_Id__c!=null and Nav_Id_Non_Billable__c!=null Order by createdDate desc limit 1];
        String temp = wh.Nav_Id__c;
        wh.Billable_Hours__c = 0;
        update wh;
        wh.Nav_Id__c = temp;
        update wh;
        delete wh;
        undelete wh;
        Working_Days__c wd = [select id,createdDate from Working_Days__c where Nav_Id__c!=null Order by createdDate desc limit 1];
        delete wd;
        undelete wd;
        Test.stopTest();
    }
}