@isTest(seealldata=true)
public class OpportunityLineItemZedRollTest{
static testMethod void tes(){
update [select id from OpportunityLineItem limit 1];
}
}