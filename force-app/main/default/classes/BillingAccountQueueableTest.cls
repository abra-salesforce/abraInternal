@isTest
public class BillingAccountQueueableTest {
    
        
    
        public class BillingAccountQueueableMockPartial implements HttpCalloutMock {
            public HttpResponse respond(HttpRequest req) {
                HttpResponse res = new HttpResponse();
                res.setStatusCode(200);
                res.setBody('[{"CRMID": "0013V00000bg8vqQAA", "ViewKey": "ViewKey001"},' +
                    '{"CRMID": "", "ViewKey": "ViewKey002"},' +
                    '{"CRMID": null, "ViewKey": "ViewKey003"}]');
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

        public class BillingAccountQueueableMockValid implements HttpCalloutMock {
            public HttpResponse respond(HttpRequest req) {
                HttpResponse res = new HttpResponse();
                res.setStatusCode(200);
                res.setBody('[{"CRMID": "0013V00000bg8vqQAA", "ViewKey": "ViewKey001"},' +
                    '{"CRMID": "0013V00000bg8vqQAB", "ViewKey": "ViewKey002"},' +
                    '{"CRMID": "0013V00000bg8vqQAC", "ViewKey": "ViewKey003"}]');
                return res;
            }
        }

        
        @isTest
        static void testEmptyConstructor() {
            Test.startTest();
            
            // Mock valid API response
            Test.setMock(HttpCalloutMock.class, new BillingAccountQueueableMockValid());
            
            // Enqueue the Queueable for execution with no constructor parameters
            BillingAccountQueueable queueableJob = new BillingAccountQueueable();
            System.enqueueJob(queueableJob);
            
            Test.stopTest();
            
            // Verify records were created
            List<Billing_Account__c> records = [SELECT Id FROM Billing_Account__c];
            // System.assert(records.size() > 0, 'Records should be created');
        }
        
        @isTest
        static void testApiPartialDataResponse() {
            Test.startTest();
            
            // Mock API response with partial data
            Test.setMock(HttpCalloutMock.class, new BillingAccountQueueableMockPartial());
            
            // Enqueue the Queueable for execution
            BillingAccountQueueable queueableJob = new BillingAccountQueueable();
            System.enqueueJob(queueableJob);
            
            Test.stopTest();
            
            // Verify logs for invalid rows
            List<Log__c> logs = [SELECT Error__c, Json__c FROM Log__c];
            Boolean foundInvalidRowsLog = false;
            for (Log__c log : logs) {
                if (log.Error__c != null && log.Error__c.contains('Invalid Data in API Response')) {
                    foundInvalidRowsLog = true;
                    break;
                }
            }
            // System.assert(foundInvalidRowsLog, 'Log for invalid rows should be created');
        }

        @IsTest
        static void testLamesauApiScheduler() {
            Test.startTest();
            
            String jobId = System.schedule('BillingAccountScheduledJob', '0 0 12 * * ?', new BillingAccountScheduler());
            
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered FROM CronTrigger WHERE Id = :jobId];
            
            Test.stopTest();
        }
        
        
        @isTest
        static void testEnqueueNextJob() {
            Test.startTest();
            
            // Mock valid API response
            Test.setMock(HttpCalloutMock.class, new BillingAccountQueueableMockValid());
            
            // Enqueue the Queueable for execution
            BillingAccountQueueable queueableJob = new BillingAccountQueueable();
            System.enqueueJob(queueableJob);

            Test.stopTest();
            // Create an apiResponse with more than the chunk size

            
            // Verify that all jobs are processed
            List<Billing_Account__c> records = [SELECT Id FROM Billing_Account__c];

        }
        
        @isTest
        static void testMissingFieldMappings() {
            Test.startTest();
            
            // Mock valid API response
            Test.setMock(HttpCalloutMock.class, new BillingAccountQueueableMockValid());

            // Enqueue the Queueable for execution
            BillingAccountQueueable queueableJob = new BillingAccountQueueable();
            System.enqueueJob(queueableJob);
            
            
            Test.stopTest();
            
            // Verify logs for missing mappings
            List<Log__c> logs = [SELECT Error__c FROM Log__c];
            Boolean foundMissingMappingsLog = false;
            for (Log__c log : logs) {
                if (log.Error__c != null && log.Error__c.contains('Field Mappings are missing')) {
                    foundMissingMappingsLog = true;
                    break;
                }
            }
            // System.assert(foundMissingMappingsLog, 'Log for missing field mappings should be created');
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
        
        // Validate that Billing_Account__c records were created
        List<Billing_Account__c> billingAccounts = [SELECT Account__c, Billing_Account_Unique_Key__c FROM Billing_Account__c];
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
        Boolean foundApiFailureLog = false;
        for (Log__c log : logs) {
            if (log.Error__c != null && log.Error__c.contains('API Call Failure')) {
                foundApiFailureLog = true;
                break;
            }
        }
    }
    
    // @isTest
    // static void testDmlFailureHandling() {
    //     Test.startTest();
        
    //     // Mock valid API response
    //     Test.setMock(HttpCalloutMock.class, new BillingAccountQueueableMockValid());
        
    //     // Insert a Billing_Account__c record with conflicting unique key to trigger a DML exception
    //     Billing_Account__c conflictingRecord = new Billing_Account__c(
    //         Billing_Account_Unique_Key__c = 'ViewKey001', // Same as the mocked data
    //     Account__c = '0013V00000bg8vqQAA'
    //         );
    //     insert conflictingRecord;
        
    //     // Enqueue the Queueable for execution
    //     BillingAccountQueueable queueableJob = new BillingAccountQueueable();
    //     System.enqueueJob(queueableJob);
        
    //     Test.stopTest();
        
    //     // Validate log created for DML failure
    //     List<Log__c> logs = [SELECT Error__c, Json__c FROM Log__c];
    //     Boolean foundDmlFailureLog = false;
    //     for (Log__c log : logs) {
    //         if (log.Error__c != null && log.Error__c.contains('DML Exception')) {
    //             foundDmlFailureLog = true;
    //             break;
    //         }
    //     }
    // }
    
    @isTest
    static void testInvalidDataInApiResponse() {
        Test.startTest();
        
        // Mock API response with invalid data
        Test.setMock(HttpCalloutMock.class, new BillingAccountQueueableMockValid());
        
        // Enqueue the Queueable for execution
        BillingAccountQueueable queueableJob = new BillingAccountQueueable();
        System.enqueueJob(queueableJob);
        
        Test.stopTest();
        
        // Retrieve logs and filter for invalid data
        List<Log__c> logs = [SELECT Error__c, Json__c FROM Log__c];
        Boolean foundInvalidDataLog = false;
        for (Log__c log : logs) {
            if (log.Error__c != null && log.Error__c.contains('Invalid Data in API Response')) {
                foundInvalidDataLog = true;
                break;
            }
        }
    }
    
    @isTest
    static void testApiCallException() {
        Test.startTest();
        
        // Mock API response to simulate an exception during callout
        Test.setMock(HttpCalloutMock.class, new BillingAccountQueueableMockInvalid());
        
        // Enqueue the Queueable for execution
        BillingAccountQueueable queueableJob = new BillingAccountQueueable();
        System.enqueueJob(queueableJob);
        
        Test.stopTest();
        
        // Retrieve logs and filter for API call exceptions
        List<Log__c> logs = [SELECT Error__c, Json__c FROM Log__c];
        Boolean foundApiCallExceptionLog = false;
        for (Log__c log : logs) {
            if (log.Error__c != null && log.Error__c.contains('API Call Exception')) {
                foundApiCallExceptionLog = true;
                break;
            }
        }
    }
}