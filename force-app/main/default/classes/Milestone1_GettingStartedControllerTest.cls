@isTest
public with sharing class Milestone1_GettingStartedControllerTest {
    @IsTest
    static void testGetSettings() {
        
        Milestone1_GettingStartedController cont = new Milestone1_GettingStartedController();
        
        Milestone1_Settings__c settings = cont.getInitialSettingsWithoutSave();
        /*
        System.assert(settings.Report_Id_Blocked_Tasks_by_Project__c != null);
        System.assert(settings.Report_Id_My_tasks_by_project__c != null);
        System.assert(settings.Report_Id_Overdue_Tasks_by_Project__c != null);
        System.assert(settings.Report_Id_Task_Status_By_Project__c != null);
        System.assert(settings.Report_Id_Open_Task_Status_by_Project__c != null);
        System.assert(settings.Report_Id_Project_Milestone_Open_Task__c != null);
        System.assert(settings.Report_Id_My_Tasks_By_Project_Milesto__c != null);
        System.assert(settings.Report_Id_My_Tasks_By_Priority_Project__c != null);
        System.assert(settings.Report_Id_My_Blocked_Tasks__c != null);
        System.assert(settings.Report_Id_My_Late_Tasks__c != null);
         */
        System.assert(!settings.Auto_Follow_Complete_Task__c);
        System.assert(!settings.Auto_Follow_Task__c);
        System.assert(!settings.Auto_Unfollow_Reassignment__c);
        
    }
    
    
    @IsTest
    static void testGettingStartedProject() {
        
        Test.startTest();
        
        Milestone1_GettingStartedController cont = new Milestone1_GettingStartedController();
        
        Milestone1_Project__c project = cont.handleGettingStartedProjectInitialization();
        
        System.assert(project != null);
        
        Test.stopTest();
        
        
    }
}