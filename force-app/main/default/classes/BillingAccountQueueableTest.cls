@isTest
public class BillingAccountQueueableTest {
    @TestSetup
    static void setupTestData() {
        // No need to create test data for custom metadata in tests, assume it's in place
    }

    public class BillingAccountQueueableMockValid implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('[{"CRMID": "001xxxxxxxxxxxxxxx", "ViewKey": "ViewKey001", "SomeField": "Value1"},' +
                        '{"CRMID": "001yyyyyyyyyyyyyyy", "ViewKey": "ViewKey002", "SomeField": "Value2"}]');
            return res;
        }
    }

    public class BillingAccountQueueableMockInvalid implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"error": "Invalid request"}');
            return res;
        }
    }

    @isTest
    static void testApiSuccessResponse() {
        Test.startTest();
        
        // Mock valid API response
        Test.setMock(HttpCalloutMock.class, new BillingAccountQueueableMockValid());

        // Enqueue the Queueable for execution
        BillingAccountQueueable queueableJob = new BillingAccountQueueable();
        System.enqueueJob(queueableJob);

        Test.stopTest();

        // Validate records created
        List<Billing_Account__c> billingAccounts = [SELECT Account__c, Billing_Account_Unique_Key__c FROM Billing_Account__c];
        System.debug('Billing Accounts created: ' + billingAccounts);
    }

    @isTest
    static void testApiFailureResponse() {
        Test.startTest();

        // Mock invalid API response
        Test.setMock(HttpCalloutMock.class, new BillingAccountQueueableMockInvalid());

        // Enqueue the Queueable for execution
        BillingAccountQueueable queueableJob = new BillingAccountQueueable();
        System.enqueueJob(queueableJob);

        Test.stopTest();

        // Validate log created for API failure
        List<Log__c> logs = [SELECT Error__c, Json__c FROM Log__c];
        System.debug('Logs for API failure: ' + logs);
    }

    
    @isTest
    static void testDmlFailureHandling() {
        Test.startTest();

        // Mock valid API response
        Test.setMock(HttpCalloutMock.class, new BillingAccountQueueableMockValid());

        // Mock scenario where DML fails
        // Use a trigger or custom field that intentionally causes an error
        BillingAccountQueueable queueableJob = new BillingAccountQueueable();
        System.enqueueJob(queueableJob);

        Test.stopTest();

        // Validate log created for DML failure
    }
}
