global class BillingAccountBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {
    
    // Endpoint URL
    private static final String ENDPOINT = 'https://abra-psaapi-test.azurewebsites.net/api/SalesForceInterface/GetCustomers?companyName=ITmyway';
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug('Starting batch process...');
        // Use CMDT or relevant query to get mappings or required configurations
        return Database.getQueryLocator([SELECT Nav_Field_API__c, SF_Field_API__c, Field_Type__c FROM Nav_Fields_Mapping__mdt]);
    }
     
    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        try {
            System.debug('Executing batch with scope size: ' + scope.size());
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
            
            System.debug('API response status code: ' + response.getStatusCode());
            
            if (response.getStatusCode() == 200) {
                List<Object> result = (List<Object>) JSON.deserializeUntyped(response.getBody());
                System.debug('Number of records received from API: ' + result.size());
                
                processResponseDataInBatches(result);
            } else {
                System.debug('API call failed with status code: ' + response.getStatusCode());
            }
        } catch (Exception ex) {
            System.debug('Unexpected Error in execute: ' + ex.getMessage());
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        System.debug('Batch processing completed.');
    }
    
    private void processResponseDataInBatches(List<Object> result) {
        System.debug('Processing response data in batches...');
        List<Map<String, Object>> batchData = new List<Map<String, Object>>();
        List<Billing_Account__c> recordsToUpsert = new List<Billing_Account__c>();

        Map<String, Map<String, String>> fieldMappings = new Map<String, Map<String, String>>();
        for (Nav_Fields_Mapping__mdt mapping : [SELECT Nav_Field_API__c, SF_Field_API__c, Field_Type__c FROM Nav_Fields_Mapping__mdt]) {
            fieldMappings.put(mapping.Nav_Field_API__c, new Map<String, String>{
                'SF_Field_API__c' => mapping.SF_Field_API__c,
                'Field_Type__c' => mapping.Field_Type__c
            });
        }

        for (Object item : result) {
            Map<String, Object> data = (Map<String, Object>) item;

            try {
                String crmId = (String) data.get('CRMID');
                if (String.isEmpty(crmId) || !crmId.startsWith('001') || crmId.length() != 18) {
                    System.debug('Skipping record due to invalid CRMID: ' + data);
                    continue;
                }

                Billing_Account__c record = new Billing_Account__c();
                System.debug('Processing record: ' + data);

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
                                System.debug('Mapped Date field ' + navField + ' to ' + mapping.get('SF_Field_API__c') + ' with value: ' + parsedDate);
                            } catch (Exception e) {
                                System.debug('Error parsing date for field ' + navField + ': ' + e.getMessage());
                                continue;
                            }
                        } else if (value != null && !String.isEmpty((String) value)) {
                            record.put(mapping.get('SF_Field_API__c'), value);
                            System.debug('Mapped field ' + navField + ' to ' + mapping.get('SF_Field_API__c') + ' with value: ' + value);
                        }
                    }
                }

                record.Account__c = crmId;
                System.debug('Set Account__c to: ' + record.Account__c);

                if (data.containsKey('ViewKey')) {
                    record.put('Billing_Account_Unique_Key__c', (String) data.get('ViewKey'));
                    System.debug('Set Billing_Account_Unique_Key__c to: ' + data.get('ViewKey'));
                }

                recordsToUpsert.add(record);

                if (recordsToUpsert.size() == 200) {
                    System.debug('Upserting batch of 200 records...');
                    upsertRecords(recordsToUpsert);
                    recordsToUpsert.clear();
                }

            } catch (Exception ex) {
                System.debug('Error processing record: ' + data + '. Error: ' + ex.getMessage());
            }
        }

        if (!recordsToUpsert.isEmpty()) {
            System.debug('Upserting remaining records: ' + recordsToUpsert.size());
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
                    // Extracting specific fields to avoid log truncation
                    String failedRecordDetails = 'Account__c=' + records[i].Account__c + 
                                                 ', Name=' + records[i].Name + 
                                                 ', Billing_Account_Unique_Key__c=' + records[i].Billing_Account_Unique_Key__c;
                    System.debug('Failed to upsert record: ' + failedRecordDetails + 
                                 '. Error: ' + results[i].getErrors()[0].getMessage());
                }
            }
        } catch (Exception ex) {
            System.debug('Error during upsert: ' + ex.getMessage());
        }
    }
}
