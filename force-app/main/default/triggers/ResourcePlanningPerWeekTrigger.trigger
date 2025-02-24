/**
 * @description       : 
 * @author            : Lioz Elmalem
 * @group             : 
 * @last modified on  : 05-16-2022
 * @last modified by  : Lioz Elmalem
**/
trigger ResourcePlanningPerWeekTrigger on Resource_Planning_Per_Week__c (before insert/*, before update*/) {
    List<Resource_Planning_Per_Week__c> ressThatNeedNewMonthlys = new List<Resource_Planning_Per_Week__c>();
    if(Trigger.isInsert ){
        for(Resource_Planning_Per_Week__c res :  Trigger.new){
            if(res.Working_Team_Resource__c != null)
                ressThatNeedNewMonthlys.add(res);
        }
    }
    if(!ressThatNeedNewMonthlys.isEmpty()) 
        MonthlyController.attachAndDisattachMonthlysTo(ressThatNeedNewMonthlys, 'Resource_Planning_Per_Week__c', true);
}