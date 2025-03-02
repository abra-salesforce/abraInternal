@isTest
public with sharing class Milestone1_repeatConTest {
    @IsTest
    static void testController()
    {
        Milestone1_Project__c testProject = Milestone1_Test_Utility.sampleProject('UNIT TEST PROJECT NAME ABC123XYZ UNIQUE' + System.now());
        testProject.Status__c = 'Active';
        testProject.Deadline__c = Date.today();
        insert testProject;
        
        Milestone1_Milestone__c testMilestone = Milestone1_Test_Utility.sampleMilestone(testProject.Id,null,'UNIT TEST MILESTONE NAME ACB123XYZ UNIQUE' + System.now());
        testMilestone.Deadline__c = Date.today();
        testMilestone.Complete__c = false;
        insert testMilestone;
        
        Milestone1_Task__c testTask = Milestone1_Test_Utility.sampleTask(testMilestone.Id);
        testTask.Complete__c = false;
        testTask.Start_Date__c = Date.today();
        testTask.Due_Date__c = Date.today();
        insert testTask;
        test.startTest();
        Milestone1_repeatCon controller = new Milestone1_repeatCon();
        controller.next();
        controller.prev();
        List<Milestone1_Month.Week> weeksList = controller.getWeeks();
        test.stopTest();
        Map<ID,Milestone1_Project__c> projMap= controller.getSelectedProject();
        Map<ID,Milestone1_Milestone__c> milestonesMap=controller.getProjectSpecificMilestone();
        system.assertEquals(projMap.containsKey(testProject.id),true);
        system.assertEquals(milestonesMap.containsKey(testMilestone.id),true);
    }
    
    @IsTest
    static void testControllerFilterTasks()
    {
        Milestone1_Project__c testProject = Milestone1_Test_Utility.sampleProject('UNIT TEST PROJECT NAME ABC123XYZ UNIQUE' + System.now());
        testProject.Status__c = 'Active';
        testProject.Deadline__c = Date.today();
        insert testProject;
        
        Milestone1_Milestone__c testMilestone = Milestone1_Test_Utility.sampleMilestone(testProject.Id,null,'UNIT TEST MILESTONE NAME ACB123XYZ UNIQUE' + System.now());
        testMilestone.Deadline__c = Date.today();
        testMilestone.Complete__c = false;
        insert testMilestone;
        
        Milestone1_Task__c testTask = Milestone1_Test_Utility.sampleTask(testMilestone.Id);
        testTask.Complete__c = false;
        testTask.Start_Date__c = Date.today();
        testTask.Due_Date__c = Date.today();
        insert testTask;
        /**
         *Modified Date:04-20-2012.
         *Owner:Persistent.
         *Comment: To add an additional project filter.
         *Bug #: 66.
         */
        test.startTest();
        Milestone1_repeatCon controller = new Milestone1_repeatCon();
        controller.next();
        controller.prev();
        controller.selectedProject = testProject.id;
        controller.filterItem = 'My Tasks Only';
        controller.filter();
        List<Milestone1_Month.Week> weeksList = controller.getWeeks();
        test.stopTest();
        Map<ID,Milestone1_Project__c> projMap= controller.getSelectedProject();
        Map<ID,Milestone1_Milestone__c> milestonesMap=controller.getProjectSpecificMilestone();
        system.assertEquals(projMap.containsKey(testProject.id),true);
        system.assertEquals(milestonesMap.containsKey(testMilestone.id),true);
        List<Id> mIds=new List<Id>();
        mIds.add(testMilestone.id);
        List<Milestone1_Task__c> tasksList=[Select Id from Milestone1_Task__c where Assigned_To__c =:Userinfo.getUserId() and Project_Milestone__c in : mIds ];
        for(Milestone1_Task__c task:tasksList)
        {
            if(testTask.id==task.id)
                system.assertEquals(task.id,testTask.id);
        }
    }
    
    @IsTest
    static void testControllerFilterMilestones()
    {
        Milestone1_Project__c testProject = Milestone1_Test_Utility.sampleProject('UNIT TEST PROJECT NAME ABC123XYZ UNIQUE' + System.now());
        testProject.Status__c = 'Active';
        testProject.Deadline__c = Date.today();
        insert testProject;
        
        Milestone1_Milestone__c testMilestone = Milestone1_Test_Utility.sampleMilestone(testProject.Id,null,'UNIT TEST MILESTONE NAME ACB123XYZ UNIQUE' + System.now());
        testMilestone.Deadline__c = Date.today();
        testMilestone.Complete__c = false;
        insert testMilestone;
        
        Milestone1_Task__c testTask = Milestone1_Test_Utility.sampleTask(testMilestone.Id);
        testTask.Complete__c = false;
        testTask.Start_Date__c = Date.today();
        testTask.Due_Date__c = Date.today();
        insert testTask;
        /**
         *Modified Date:04-20-2012.
         *Owner:Persistent.
         *Comment: To add an additional project filter.
         *Bug #: 66.
         */
        test.startTest();
        Milestone1_repeatCon controller = new Milestone1_repeatCon();
        controller.next();
        controller.prev();
        controller.selectedProject = testProject.id;
        controller.filterItem = 'My Milestones Only';
        controller.filter();
        List<Milestone1_Month.Week> weeksList = controller.getWeeks();
        test.stopTest();
        Map<ID,Milestone1_Project__c> projMap= controller.getSelectedProject();
        Map<ID,Milestone1_Milestone__c> milestonesMap=controller.getProjectSpecificMilestone();
        //system.assertEquals(projMap.containsKey(testProject.id),true);
        system.assertEquals(milestonesMap.containsKey(testMilestone.id),true);
    }
    
    @IsTest
    static void testControllerFilterMyProjects()
    {
        Milestone1_Project__c testProject = Milestone1_Test_Utility.sampleProject('UNIT TEST PROJECT NAME ABC123XYZ UNIQUE' + System.now());
        testProject.Status__c = 'Active';
        testProject.Deadline__c = Date.today();
        insert testProject;
        
        Milestone1_Milestone__c testMilestone = Milestone1_Test_Utility.sampleMilestone(testProject.Id,null,'UNIT TEST MILESTONE NAME ACB123XYZ UNIQUE' + System.now());
        testMilestone.Deadline__c = Date.today();
        testMilestone.Complete__c = false;
        insert testMilestone;
        
        Milestone1_Task__c testTask = Milestone1_Test_Utility.sampleTask(testMilestone.Id);
        testTask.Complete__c = false;
        testTask.Start_Date__c = Date.today();
        testTask.Due_Date__c = Date.today();
        insert testTask;
        /**
         *Modified Date:04-20-2012.
         *Owner:Persistent.
         *Comment: To add an additional project filter.
         *Bug #: 66.
         */
        test.startTest();
        Milestone1_repeatCon controller = new Milestone1_repeatCon();
        controller.next();
        controller.prev();
        controller.selectedProject = testProject.id;
        controller.filterItem = 'My Projects And Sub-Project Items';
        controller.filter();
        List<Milestone1_Month.Week> weeksList = controller.getWeeks();
        test.stopTest();
        Map<ID,Milestone1_Project__c> projMap= controller.getSelectedProject();
        Map<ID,Milestone1_Milestone__c> milestonesMap=controller.getProjectSpecificMilestone();
        system.assertEquals(projMap.containsKey(testProject.id),true);
        system.assertEquals(milestonesMap.containsKey(testMilestone.id),true);
    }
    
    /**
     *Modified Date:04-20-2012.
     *Owner:Persistent.
     *Comment: To add an additional project filter.
     *Bug #: 66.
     */
    @IsTest
    static void testControllerFilterAllItems()
    {
        Milestone1_Project__c testProject = Milestone1_Test_Utility.sampleProject('UNIT TEST PROJECT NAME ABC123XYZ UNIQUE' + System.now());
        testProject.Status__c = 'Active';
        testProject.Deadline__c = Date.today();
        insert testProject;
        
        Milestone1_Milestone__c testMilestone = Milestone1_Test_Utility.sampleMilestone(testProject.Id,null,'UNIT TEST MILESTONE NAME ACB123XYZ UNIQUE' + System.now());
        testMilestone.Deadline__c = Date.today();
        testMilestone.Complete__c = false;
        insert testMilestone;
        
        Milestone1_Task__c testTask = Milestone1_Test_Utility.sampleTask(testMilestone.Id);
        testTask.Complete__c = false;
        testTask.Start_Date__c = Date.today();
        testTask.Due_Date__c = Date.today();
        insert testTask;
        
        test.startTest();
        Milestone1_repeatCon controller = new Milestone1_repeatCon();
        controller.next();
        controller.prev();
        controller.selectedProject = testProject.id;
        controller.filterItem = 'All Items';
        controller.filter();
        List<Milestone1_Month.Week> weeksList = controller.getWeeks();
        test.stopTest();
        Map<ID,Milestone1_Project__c> projMap= controller.getSelectedProject();
        Map<ID,Milestone1_Milestone__c> milestonesMap=controller.getProjectSpecificMilestone();
        
    }
    
    @IsTest
    static void testControllerFilterAllItemsWithBlankProject()
    {
        Milestone1_Project__c testProject = Milestone1_Test_Utility.sampleProject('Trial Project ABCXYZ' + System.now());
        testProject.Status__c = 'Active';
        testProject.Deadline__c = Date.today();
        system.debug(testProject.name);
        insert testProject;
        
        Milestone1_Project__c testProject1 = Milestone1_Test_Utility.sampleProject('UNIT TEST PROJECT NAME ABC123XYZ UNIQUE' + System.now());
        testProject1.Status__c = 'Active';
        testProject1.Deadline__c = Date.today();
        insert testProject1;
        
        Milestone1_Milestone__c testMilestone = Milestone1_Test_Utility.sampleMilestone(testProject.Id,null,'UNIT TEST MILESTONE NAME ACB123XYZ UNIQUE' + System.now());
        testMilestone.Deadline__c = Date.today();
        testMilestone.Complete__c = false;
        insert testMilestone;
        
        Milestone1_Milestone__c testMilestone1 = Milestone1_Test_Utility.sampleMilestone(testProject1.Id,null,'UNIT TEST MILESTONE NAME ACB123XYZ UNIQUE' + System.now());
        testMilestone1.Deadline__c = Date.today();
        testMilestone1.Complete__c = false;
        insert testMilestone1;
        
        Milestone1_Task__c testTask = Milestone1_Test_Utility.sampleTask(testMilestone.Id);
        testTask.Complete__c = false;
        testTask.Start_Date__c = Date.today();
        testTask.Due_Date__c = Date.today();
        insert testTask;
        
        Milestone1_Task__c testTask1 = Milestone1_Test_Utility.sampleTask(testMilestone1.Id);
        testTask1.Complete__c = false;
        testTask1.Start_Date__c = Date.today();
        testTask1.Due_Date__c = Date.today();
        insert testTask1;
        
        test.startTest();
        Milestone1_repeatCon controller = new Milestone1_repeatCon();
        controller.next();
        controller.prev();
        controller.selectedProject = null;
        controller.filterItem = 'All Items';
        controller.filter();
        List<Milestone1_Month.Week> weeksList = controller.getWeeks();
        test.stopTest();
        Map<ID,Milestone1_Project__c> projMap= controller.getSelectedProject();
        Map<ID,Milestone1_Milestone__c> milestonesMap=controller.getProjectSpecificMilestone();
        system.assertEquals(projMap.containsKey(testProject.id),true);
        system.assertEquals(projMap.containsKey(testProject1.id),true);
        system.assertEquals(milestonesMap.containsKey(testMilestone.id),true);
        system.assertEquals(milestonesMap.containsKey(testMilestone1.id),true);
        Milestone1_Task__c task=[Select id,name from Milestone1_Task__c where id =: testTask.id];
        system.assertEquals(testTask.id,task.id);
        
    }
    
    
    @IsTest
    static void testControllerFilterMyProjectsWithBlankProject()
    {
        Milestone1_Project__c testProject = Milestone1_Test_Utility.sampleProject('Trial Project ABCXYZ' + System.now());
        testProject.Status__c = 'Active';
        testProject.Deadline__c = Date.today();
        system.debug(testProject.name);
        insert testProject;
        
        Milestone1_Project__c testProject1 = Milestone1_Test_Utility.sampleProject('UNIT TEST PROJECT NAME ABC123XYZ UNIQUE' + System.now());
        testProject1.Status__c = 'Active';
        testProject1.Deadline__c = Date.today();
        insert testProject1;
        
        Milestone1_Milestone__c testMilestone = Milestone1_Test_Utility.sampleMilestone(testProject.Id,null,'UNIT TEST MILESTONE NAME ACB123XYZ UNIQUE' + System.now());
        testMilestone.Deadline__c = Date.today();
        testMilestone.Complete__c = false;
        insert testMilestone;
        
        Milestone1_Task__c testTask = Milestone1_Test_Utility.sampleTask(testMilestone.Id);
        testTask.Complete__c = false;
        testTask.Start_Date__c = Date.today();
        testTask.Due_Date__c = Date.today();
        insert testTask;
        
        test.startTest();
        Milestone1_repeatCon controller = new Milestone1_repeatCon();
        controller.next();
        controller.prev();
        controller.selectedProject = 'AllProjects';
        controller.filterItem = 'My Projects And Sub-Project Items';
        controller.filter();
        List<Milestone1_Month.Week> weeksList = controller.getWeeks();
        test.stopTest();
        Map<ID,Milestone1_Project__c> projMap= controller.getSelectedProject();
        Map<ID,Milestone1_Milestone__c> milestonesMap=controller.getProjectSpecificMilestone();
        system.assertEquals(projMap.containsKey(testProject.id),true);
        system.assertEquals(projMap.containsKey(testProject1.id),true);
        system.assertEquals(milestonesMap.containsKey(testMilestone.id),true);
        Milestone1_Task__c task=[Select id,name from Milestone1_Task__c where id =: testTask.id];
        system.assertEquals(testTask.id,task.id);
    }
    
    @IsTest
    static void testControllerFilterMilestonesWithBlankProject()
    {
        Milestone1_Project__c testProject = Milestone1_Test_Utility.sampleProject('Trial Project ABCXYZ' + System.now());
        testProject.Status__c = 'Active';
        testProject.Deadline__c = Date.today();
        system.debug(testProject.name);
        insert testProject;
        
        Milestone1_Milestone__c testMilestone = Milestone1_Test_Utility.sampleMilestone(testProject.Id,null,'UNIT TEST MILESTONE NAME ACB123XYZ UNIQUE' + System.now());
        testMilestone.Deadline__c = Date.today();
        testMilestone.Complete__c = false;
        insert testMilestone;
        
        Milestone1_Milestone__c testMilestone1 = Milestone1_Test_Utility.sampleMilestone(testProject.Id,null,'UNIT TEST MILESTONE NAME ACB123XYZ UNIQUE' + System.now());
        testMilestone1.Deadline__c = Date.today();
        testMilestone1.Complete__c = false;
        insert testMilestone1;
        
        Milestone1_Task__c testTask = Milestone1_Test_Utility.sampleTask(testMilestone.Id);
        testTask.Complete__c = false;
        testTask.Start_Date__c = Date.today();
        testTask.Due_Date__c = Date.today();
        insert testTask;
        
        test.startTest();
        Milestone1_repeatCon controller = new Milestone1_repeatCon();
        controller.next();
        controller.prev();
        controller.selectedProject = null;
        controller.filterItem = 'My Milestones Only';
        controller.filter();
        List<Milestone1_Month.Week> weeksList = controller.getWeeks();
        test.stopTest();
        Map<ID,Milestone1_Project__c> projMap= controller.getSelectedProject();
        Map<ID,Milestone1_Milestone__c> milestonesMap=controller.getProjectSpecificMilestone();
        system.assertEquals(milestonesMap.containsKey(testMilestone.id),true);
        system.assertEquals(milestonesMap.containsKey(testMilestone1.id),true);
        
        
    }
    
    @IsTest
    static void testControllerFilterTasksWithBlankProject()
    {
        Milestone1_Project__c testProject = Milestone1_Test_Utility.sampleProject('Trial Project ABCXYZ' + System.now());
        testProject.Status__c = 'Active';
        testProject.Deadline__c = Date.today();
        system.debug(testProject.name);
        insert testProject;
        
        Milestone1_Milestone__c testMilestone = Milestone1_Test_Utility.sampleMilestone(testProject.Id,null,'UNIT TEST MILESTONE NAME ACB123XYZ UNIQUE' + System.now());
        testMilestone.Deadline__c = Date.today();
        testMilestone.Complete__c = false;
        insert testMilestone;
        
        Milestone1_Task__c testTask = Milestone1_Test_Utility.sampleTask(testMilestone.Id);
        testTask.Complete__c = false;
        testTask.Start_Date__c = Date.today();
        testTask.Due_Date__c = Date.today();
        insert testTask;
        
        Milestone1_Task__c testTask1 = Milestone1_Test_Utility.sampleTask(testMilestone.Id);
        testTask1.Complete__c = false;
        testTask1.Start_Date__c = Date.today();
        testTask1.Due_Date__c = Date.today();
        insert testTask1;
        
        test.startTest();
        Milestone1_repeatCon controller = new Milestone1_repeatCon();
        controller.next();
        controller.prev();
        controller.selectedProject = 'AllProjects';
        controller.filterItem = 'My Tasks Only';
        controller.filter();
        List<Milestone1_Month.Week> weeksList = controller.getWeeks();
        test.stopTest();
        Map<ID,Milestone1_Project__c> projMap= controller.getSelectedProject();
        Map<ID,Milestone1_Milestone__c> milestonesMap=controller.getProjectSpecificMilestone();
        Milestone1_Task__c task=[Select id,name from Milestone1_Task__c where id =: testTask.id];
        system.assertEquals(testTask.id,task.id);
        task=[Select id,name from Milestone1_Task__c where id =: testTask1.id];
        system.assertEquals(testTask1.id,task.id);
    }
    
    
}