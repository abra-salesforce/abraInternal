@isTest
public with sharing class Milestone1_General_UtilityTest {
    @IsTest
    static void testTruncateString()
    {
        String example = 'NEW DESCRIPTION 1234567890 ABCDEFGHIJKLMNOPQRSTUVWXYZ THIS IS LONG DESCRIPTION GREATER THAN 80 CHARACTER LIMIT FOR NAME TEST TRUNCATING';
        String nameString = Milestone1_General_Utility.processTaskName(example);
        system.AssertEquals('NEW DESCRIPTION 1234567890 ABCDEFGHIJKLMNOPQRSTUVWXYZ THIS IS LONG...',nameString);
    }
    
}