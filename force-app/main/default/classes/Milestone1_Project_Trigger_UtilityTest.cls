@isTest
public with sharing class Milestone1_Project_Trigger_UtilityTest {
    /**
     * Test milestone delete
     */
    @IsTest
    public static void testMilestoneDelete(){
        // Create project
        Milestone1_Project__c project = Milestone1_Test_Utility.sampleProject('My Test Project');
        
        insert project;
        
        // Create milestones
        List<Milestone1_Milestone__c> mList = new List<Milestone1_Milestone__c>();
        
        for(Integer i = 0; i < 101; i++){
            mList.add( Milestone1_Test_Utility.sampleMilestone(project.Id, null, 'My Test Milestone ' + i) );
        }
        
        try{
            insert mList;
        }
        catch(Exception e){
            system.assert( false, e.getMessage() );
        }
        
        // Delete and check if it was successful
        try{
            Test.startTest();
            Milestone1_Project_Trigger_Utility.handleProjectDeleteTrigger( new List<Milestone1_Project__c>{ project } );
            Test.stopTest();
            
            system.assertEquals(0, [SELECT count() FROM Milestone1_Milestone__c WHERE Project__c = :project.Id]);
        }
        catch(Exception e){
            system.assert( false, e.getMessage() );
        }
    }
}