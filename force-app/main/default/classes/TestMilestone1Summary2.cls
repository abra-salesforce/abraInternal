@isTest
public with sharing class TestMilestone1Summary2 {
    
    @IsTest
    static void testController() {
        Milestone1_Summary2 summary2 = new Milestone1_Summary2();
        if (summary2.settings == null) {
            summary2.settings = new Milestone1_Settings__c();
        }
        
        Milestone1_Project__c p1 = new Milestone1_Project__c(Name = 'Controller Test', Status__c = 'Active');
        insert p1;
        
        summary2.targetProject = p1.Id;
        System.assert(summary2.view() != null);
        summary2.initialize();
        System.assert(summary2.recentItems != null);
        
        summary2.searchText = 's';
        summary2.searchProjects();
        System.assertEquals(true, summary2.hasSearchLengthError);
        
        summary2.searchText = 'Test';
        summary2.searchProjects();
        System.assert(summary2.hasSearchResultsError);
        System.assert(!summary2.hasProjectResults);
        System.assert(!summary2.hasMilestoneResults);
        System.assert(!summary2.hasTaskResults);
    }
    
}