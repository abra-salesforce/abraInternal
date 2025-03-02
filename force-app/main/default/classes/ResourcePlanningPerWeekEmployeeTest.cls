/**
 * @description       : 
 * @author            : Lioz Elmalem
 * @group             : 
 * @last modified on  : 05-16-2022
 * @last modified by  : Lioz Elmalem
**/
@IsTest(SeeAllData=true)
public class ResourcePlanningPerWeekEmployeeTest {
    @IsTest
public static void test() {
        Resource_Planning_Per_Week__c resource = [SELECT Id, Working_Team_Resource__c FROM Resource_Planning_Per_Week__c LIMIT 1];
        update resource;
    }
}