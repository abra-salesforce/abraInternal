@isTest(seealldata=true)
public class QuoteTriggerTest {
    @IsTest
static void tes(){
        insert new Quote(Name='test',Account__c=[select id from Account limit 1].id);
    }
}