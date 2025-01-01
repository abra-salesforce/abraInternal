global class BillingAccountQueueable implements Queueable, Database.AllowsCallouts {
    // Endpoint URL
    private static final String ENDPOINT = 'https://abra-psaapi-test.azurewebsites.net/api/SalesForceInterface/GetCustomers?companyName=ITmyway';

    // Store field mappings
    private Map<String, Map<String, String>> fieldMappings;

    // Constructor to initialize field mappings
    public BillingAccountQueueable() {
        fieldMappings = new Map<String, Map<String, String>>();
        for (Nav_Fields_Mapping__mdt mapping : [SELECT Nav_Field_API__c, SF_Field_API__c, Field_Type__c FROM Nav_Fields_Mapping__mdt]) {
            fieldMappings.put(mapping.Nav_Field_API__c, new Map<String, String>{
                'SF_Field_API__c' => mapping.SF_Field_API__c,
                'Field_Type__c' => mapping.Field_Type__c
            });
        }
    }

    global void execute(QueueableContext context) {
        try {
            System.debug('Executing queueable logic...');
            String ApiKey = 'ITMy8e791488-1a13-4f48-a96a-adaa9c523135Way=';
            
            // Call the API
            HttpRequest request = new HttpRequest();
            request.setEndpoint(ENDPOINT);
            request.setMethod('GET');
            request.setTimeout(120000);
            request.setHeader('ApiKey', ApiKey);
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Accept', 'application/json');
            HttpResponse response = new Http().send(request);
            
            if (response.getStatusCode() == 200) {
                List<Object> result = (List<Object>) JSON.deserializeUntyped(response.getBody());
                System.debug('Number of records received from API: ' + result.size());
                processResponseDataInChunks(result);
            } else {
                System.debug('API call failed with status code: ' + response.getStatusCode());
            }
        } catch (Exception ex) {
            System.debug('Unexpected Error in execute: ' + ex.getMessage());
        }
    }

    private void processResponseDataInChunks(List<Object> result) {
        System.debug('Processing response data in chunks...');
        Integer chunkSize = 200; // Process 200 records at a time
        List<Object> currentChunk = new List<Object>();

        for (Integer i = 0; i < result.size(); i++) {
            currentChunk.add(result[i]);

            if (currentChunk.size() == chunkSize || i == result.size() - 1) {
                System.debug('Processing chunk of size: ' + currentChunk.size());
                enqueueChunk(currentChunk);
                currentChunk.clear();
            }
        }
    }

    private void enqueueChunk(List<Object> chunk) {
        System.enqueueJob(new BillingAccountProcessingQueueable(chunk, fieldMappings));
    }
}

global class BillingAccountProcessingQueueable implements Queueable, Database.AllowsCallouts {
    private List<Object> chunk;
    private Map<String, Map<String, String>> fieldMappings;

    // Constructor to pass data
    public BillingAccountProcessingQueueable(List<Object> chunk, Map<String, Map<String, String>> fieldMappings) {
        this.chunk = chunk;
        this.fieldMappings = fieldMappings;
    }

    global void execute(QueueableContext context) {
        List<Billing_Account__c> recordsToUpsert = new List<Billing_Account__c>();

        for (Object item : chunk) {
            Map<String, Object> data = (Map<String, Object>) item;

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
                            try {
                                String dateString = (String) value;
                                Date parsedDate = Date.valueOf(dateString.substring(0, 10));
                                record.put(mapping.get('SF_Field_API__c'), parsedDate);
                            } catch (Exception e) {
                                System.debug('Error parsing date for field ' + navField + ': ' + e.getMessage());
                                continue;
                            }
                        } else if (value != null && !String.isEmpty((String) value)) {
                            record.put(mapping.get('SF_Field_API__c'), value);
                        }
                    }
                }

                record.Account__c = crmId;

                if (data.containsKey('ViewKey')) {
                    record.put('Billing_Account_Unique_Key__c', (String) data.get('ViewKey'));
                }

                recordsToUpsert.add(record);

            } catch (Exception ex) {
                System.debug('Error processing record: ' + data + '. Error: ' + ex.getMessage());
            }
        }

        if (!recordsToUpsert.isEmpty()) {
            upsertRecords(recordsToUpsert);
        }
    }

    private void upsertRecords(List<Billing_Account__c> records) {
        try {
            Database.UpsertResult[] results = Database.upsert(records, Billing_Account__c.fields.Billing_Account_Unique_Key__c, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    System.debug('Successfully upserted record: ' + records[i]);
                } else {
                    System.debug('Failed to upsert record: ' + results[i].getErrors()[0].getMessage());
                }
            }
        } catch (Exception ex) {
            System.debug('Error during upsert: ' + ex.getMessage());
        }
    }
}
