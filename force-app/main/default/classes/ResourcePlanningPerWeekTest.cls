@isTest (seealldata=true)
public with sharing class ResourcePlanningPerWeekTest {

    public static testMethod void attachResourceToMonthly(){
    
        String conId = [select id from Contact where name='Edan Badani' limit 1].id;
        Date startOfOct = date.newInstance(2021, 10, 01);
        Date startOfNov = date.newInstance(2021, 11, 01);
        startOfOct = startOfOct.addYears(2);
        startOfNov = startOfNov.addYears(2);
        String OuniqueKey = MonthlyController.initUniqueKeyFrom(conId, startOfOct);
        String NuniqueKey = MonthlyController.initUniqueKeyFrom(conId, startOfNov);

        // create two monthlys
        Monthly_Hours__c m10 = MonthlyController.createMonthly(conId, startOfOct, null);
        Monthly_Hours__c m11 = MonthlyController.createMonthly(conId, startOfNov, null);
        try{
            insert new List<Monthly_Hours__c>{m10, m11};
        }catch(exception e){}
        Project__c pTest = TestsUtil.createMeP();
		insert pTest;
        Scope_Item__c scopeT = TestsUtil.createMeSI(pTest.Id);
        insert scopeT;
        Working_Team__c testTeam = new Working_Team__c(Name = 'TestTeam');
        insert testTeam;
        Working_Team_Resource__c wTR = TestsUtil.createMeWTR(conId, testTeam.id);
        insert wTR;
        pTest.Working_Team__c = testTeam.id;
        update pTest;
		Planned_Time_Per_Week__c ptpw = [select id from Planned_Time_Per_Week__c where Scope_Item__c=:scopeT.id limit 1];
        ptpw.Assign_Budget__c = 5;
        ptpw.Assign_Working_Team_Resource__c = wTR.Id;
        update ptpw;
        MonthlyController.getConIdsFrom(new List<Working_Team_Resource__c>{wTR});

        /*Date sOfWeek = MonthlyController.sundayStartWeek(startOfOct.addDays(10));
        Planned_Time_Per_Week__c pTPW = TestsUtil.createMePTPR('TestName', scopeT.Id, sOfWeek, 50);
        insert pTPW;

        Working_Team_Resource__c wTR = TestsUtil.createMeWTR(conId);
        insert wTR;
        Working_Team_Resource__c wTR2 = TestsUtil.createMeWTR(conId);
        insert wTR2;

        // create resource --> attach to one mothly
        Resource_Planning_Per_Week__c resPlanPWeek = TestsUtil.createMeRP(pTPW.Id, null, 10);
        
        // add wTR to active wanted trigger
        resPlanPWeek.Working_Team_Resource__c = wTR.Id;
        insert resPlanPWeek;

        // change date of the resource
        resPlanPWeek.Working_Team_Resource__c = wTR2.Id;
        update resPlanPWeek;

        pTPW.Assign_Budget__c = 5;
        pTPW.Assign_Working_Team_Resource__c = wTR.Id;
        update pTPW;
        */
    }
}