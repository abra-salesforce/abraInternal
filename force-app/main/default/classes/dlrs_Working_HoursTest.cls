/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Working_HoursTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Working_HoursTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Working_Hours__c());
    }
}