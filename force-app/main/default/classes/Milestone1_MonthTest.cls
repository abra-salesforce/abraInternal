@IsTest
public with sharing class Milestone1_MonthTest {
    @IsTest
    static void testMe() {
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
        testTask.Start_Date__c = Date.today().addDays(-1);
        testTask.Due_Date__c = Date.today().addDays(-1);
        
        insert testTask;
        
        Milestone1_Month m = new Milestone1_Month( Date.today());
        system.assert(m!=null);
        List<Week> l = m.getWeeks();
        for(Week w : l)
        {
            List<Day> days = w.getDays();
            for(Day d : days)
            {
                system.debug(d.getDayOfYear());
                system.debug(d.getDayOfMonth());
                system.debug(d.getDayNumber());
                system.debug(d.getCSSName());
            }
        }
        system.debug(m.getFirstDate());
        system.debug(m.getWeekdayNames());
        system.debug(m.getYearName());
        system.debug(m.getMonthName());
        system.assert(m.getWeeks() != null);
        system.assert(m.getWeeks().size() > 3);
    }
}