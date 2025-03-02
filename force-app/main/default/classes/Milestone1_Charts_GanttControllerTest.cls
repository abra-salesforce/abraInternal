@isTest
public with sharing class Milestone1_Charts_GanttControllerTest {
    @IsTest
    static void TestProjectJson() {
            Milestone1_Project__c p1 = Milestone1_Test_Utility.sampleProjectActive('Json');
            insert p1;
            Milestone1_Milestone__c m1 = Milestone1_Test_Utility.sampleMilestone(p1);
            insert m1;
            
            Milestone1_Charts_GanttController cls = new Milestone1_Charts_GanttController();
            cls.mytarget = p1.id;
    
            String ret = cls.getProjectGanttJson();
            
            System.assert(ret.indexOf('ganttData') > -1);
            System.assert(ret.indexOf(m1.Name) > -1);    
            //RSC 2011-05-09 bad test -- fails when there is an interesting dateformat.
            //System.assert(ret.indexOf(Date.today().format().substring(5)) > -1); // Test today's
            String testDateString = 'new Date(' +m1.Kickoff__c.year() +',' + (m1.Kickoff__c.month()-1) +',' + m1.Kickoff__c.day() +')';
            System.assert(ret.indexOf(testDateString) > -1, 'expected: ' + testDateString + ': in: ' + ret);
        
            m1.Complete__c = true;
            update m1;
        
            Milestone1_Milestone__c m2 = Milestone1_Test_Utility.sampleMilestone(p1);
            m2.Deadline__c = Date.today()-1;
            insert m2;    
            
            Milestone1_Milestone__c m3 = Milestone1_Test_Utility.sampleMilestone(p1);
            m3.Kickoff__c = Date.today()+1;
            insert m3;            
        
            ret = cls.getProjectGanttJson();
            
            System.assert(ret.indexOf(Milestone1_Charts_GanttController.COLOR_COMPLETE) > -1);
            System.assert(ret.indexOf(Milestone1_Charts_GanttController.COLOR_LATE) > -1);
            System.assert(ret.indexOf(Milestone1_Charts_GanttController.COLOR_FUTURE) > -1);
            
                    
        }
        
        @IsTest
    static void TestMilestoneJson() {
            Milestone1_Project__c p1 = Milestone1_Test_Utility.sampleProjectActive('Json');
            insert p1;
            
              Milestone1_Milestone__c m2 = Milestone1_Test_Utility.sampleMilestone(p1);
            m2.Deadline__c = Date.today()-1;
            insert m2;   
            
            Milestone1_Task__c t1 = Milestone1_Test_Utility.sampleTask(m2.Id);
            insert t1;
            
            Milestone1_Charts_GanttController cls = new Milestone1_Charts_GanttController();
            cls.mytarget = m2.Id;
            String ret = cls.getProjectGanttJson();
                       
            System.debug(LoggingLevel.Info, '12345:' + ret);
            
            System.assert(ret.indexOf(Milestone1_Charts_GanttController.COLOR_FUTURE) > -1);     
           }}