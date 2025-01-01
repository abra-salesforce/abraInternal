global class BillingAccountQueueable implements Queueable, Database.AllowsCallouts {
    private List<Object> apiResponse; // Holds the API response
    private Integer startIndex; // Tracks the starting index of the batch

    // Constructor to pass API response and starting index for the batch
    public BillingAccountQueueable() {
        this.apiResponse = new List<Object>();
        this.startIndex = 0;
    }

    public BillingAccountQueueable(List<Object> apiResponse, Integer startIndex) {
        this.apiResponse = apiResponse;
        this.startIndex = startIndex;
    }

    global void execute(QueueableContext context) {
        try {
            // If this is the first execution, fetch the API response
            if (apiResponse.isEmpty()) {
                Nav_Setting__mdt settings = getSettings();
                apiResponse = callApi(settings);
                if (apiResponse.isEmpty()) {
                    System.debug('No data retrieved from API.');
                    return;
                }
            }

            // Process the current batch
            Integer chunkSize = 200;
            Integer endIndex = Math.min(startIndex + chunkSize, apiResponse.size());
            System.debug('Processing records from index ' + startIndex + ' to ' + (endIndex - 1));

            List<Billing_Account__c> recordsToUpsert = new List<Billing_Account__c>();

            // Retrieve field mappings
            Map<String, Map<String, String>> fieldMappings = getFieldMappings();

            for (Integer i = startIndex; i < endIndex; i++) {
                Map<String, Object> data = (Map<String, Object>) apiResponse[i];
                try {
                    String crmId = (String) data.get('CRMID');
                    if (String.isEmpty(crmId) || !crmId.startsWith('001') || crmId.length() != 18) {
                        System.debug('Skipping record due to invalid CRMID: ' + data);
                        continue;
                    }

                    Billing_Account__c record = new Billing_Account__c();
                    for (String navField : fieldMappings.keySet()) {
                        if (data.containsKey(navField)) {
                            Map<String, String> mapping = fieldMappings.get(navField);
                            String fieldType = mapping.get('Field_Type__c');
                            Object value = data.get(navField);

                            if (fieldType == 'Date' && value != null) {
                                String dateString = (String) value;
                                record.put(mapping.get('SF_Field_API__c'), Date.valueOf(dateString.substring(0, 10)));
                            } else if (value != null) {
                                record.put(mapping.get('SF_Field_API__c'), value);
                            }
                        }
                    }

                    record.Account__c = crmId;
                    if (data.containsKey('ViewKey')) {
                        record.Billing_Account_Unique_Key__c = (String) data.get('ViewKey');
                    }

                    recordsToUpsert.add(record);
                } catch (Exception ex) {
                    System.debug('Error processing record: ' + ex.getMessage());
                }
            }

            // Upsert the current batch
            if (!recordsToUpsert.isEmpty()) {
                upsertRecords(recordsToUpsert);
            }

            // Enqueue the next batch if there are more records
            if (endIndex < apiResponse.size() && !Test.isRunningTest()) {
                System.debug('Enqueuing next batch starting at index ' + endIndex);
                System.enqueueJob(new BillingAccountQueueable(apiResponse, endIndex));
            }
        } catch (Exception ex) {
            System.debug('Unexpected error: ' + ex.getMessage());
        }
    }

    private List<Object> callApi(Nav_Setting__mdt settings) {
        try {
            HttpRequest request = new HttpRequest();
            request.setEndpoint(settings.Endpoint__c + '/SalesForceInterface/GetCustomers?companyName=ITmyway');
            request.setMethod('GET');
            request.setTimeout(120000);
            request.setHeader('ApiKey', settings.Api_Key__c);
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Accept', 'application/json');

            HttpResponse response = new Http().send(request);
            System.debug('API response status code: ' + response.getStatusCode());

            if (response.getStatusCode() == 200) {
                return (List<Object>) JSON.deserializeUntyped(response.getBody());
            } else {
                System.debug('API call failed with status code: ' + response.getStatusCode());
            }
        } catch (Exception ex) {
            System.debug('Error during API call: ' + ex.getMessage());
        }
        return new List<Object>();
    }

    private void upsertRecords(List<Billing_Account__c> records) {
        try {
            Database.UpsertResult[] results = Database.upsert(records, Billing_Account__c.fields.Billing_Account_Unique_Key__c, false);
            for (Database.UpsertResult result : results) {
                if (!result.isSuccess()) {
                    System.debug('Failed to upsert record: ' + result.getErrors()[0].getMessage());
                }
            }
            System.debug('Successfully upserted ' + records.size() + ' records.');
        } catch (Exception ex) {
            System.debug('Error during upsert: ' + ex.getMessage());
        }
    }

    private Map<String, Map<String, String>> getFieldMappings() {
        Map<String, Map<String, String>> fieldMappings = new Map<String, Map<String, String>>();
        for (Nav_Fields_Mapping__mdt mapping : [SELECT Nav_Field_API__c, SF_Field_API__c, Field_Type__c FROM Nav_Fields_Mapping__mdt]) {
            fieldMappings.put(mapping.Nav_Field_API__c, new Map<String, String>{
                'SF_Field_API__c' => mapping.SF_Field_API__c,
                'Field_Type__c' => mapping.Field_Type__c
            });
        }
        return fieldMappings;
    }

    public static Nav_Setting__mdt getSettings() {
        String org = ([SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox) ? 'Sandbox' : 'Production';
        return [SELECT Id, Endpoint__c, Api_Key__c FROM Nav_Setting__mdt WHERE DeveloperName = :org LIMIT 1];
    }
}
