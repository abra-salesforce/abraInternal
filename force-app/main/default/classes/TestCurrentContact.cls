@IsTest (seealldata=true)
public with sharing class TestCurrentContact {
    @IsTest static void test1() {
        issue__c iss=[select id from issue__c limit 1];
		currentContact.getContact();
        currentContact.getAccountProject(iss.id);
        currentContact.getContactRecord();
    }
}