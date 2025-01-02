global class BillingAccountQueueable implements Queueable, Database.AllowsCallouts {
    private static final Integer chunkSize = 200;
    private List<Object> apiResponse;
    private Map<String, Map<String, String>> fieldMappings;
    private Integer startIndex;
    String errorMessage = '';
    
    public BillingAccountQueueable() {
        this.apiResponse = new List<Object>();
        this.startIndex = 0;
    }
    
    public BillingAccountQueueable(List<Object> apiResponse, Integer startIndex, Map<String, Map<String, String>> fieldMappings) {
        this.apiResponse = apiResponse;
        this.startIndex = startIndex;
        this.fieldMappings = fieldMappings;
        this.errorMessage = '';
    }
    
    global void execute(QueueableContext context) {
        try {
            if (apiResponse.isEmpty()) {
                Nav_Setting__mdt settings = getSettings();
                fieldMappings = getFieldMappings();
                apiResponse = callApi(settings);
                if (apiResponse.isEmpty()) {
                    createLog('API response is empty', 'No data retrieved from API.', 'Inbound', null);
                    return;
                }
            }
            
            Integer endIndex = Math.min(startIndex + chunkSize, apiResponse.size());
            System.debug('Processing records from index ' + startIndex + ' to ' + (endIndex - 1));
            
            List<Billing_Account__c> recordsToUpsert = new List<Billing_Account__c>();
            List<Map<String, Object>> invalidRows = new List<Map<String, Object>>();
            
            for (Integer i = startIndex; i < endIndex; i++) {
                Map<String, Object> data = (Map<String, Object>) apiResponse[i];
                try {
                    String crmId = (String) data.get('CRMID');
                    String viewKey = (String) data.get('ViewKey');
                    
                    if (String.isBlank(viewKey)) {
                        errorMessage += 'Record skipped: ViewKey is empty or invalid. Record Data: ' + data.get('ViewKey') + '\n';

                        invalidRows.add(data);
                        continue;
                    }
                    
                    if (String.isEmpty(crmId) || !crmId.startsWith('001') || crmId.length() != 18) {
                        invalidRows.add(data);
                        errorMessage += 'Record skipped: CRMID is empty or invalid. Record Data: ' + data.get('CRMID') + '\n';
                        continue;
                    }
                    
                    Billing_Account__c record = new Billing_Account__c();
                    for (String navField : fieldMappings.keySet()) {
                        if (data.containsKey(navField)) {
                            Map<String, String> mapping = fieldMappings.get(navField);
                            String fieldType = mapping.get('Field_Type__c');
                            Object value = data.get(navField);
                            
                            if (fieldType == 'Date' && value != null) {
                                record.put(mapping.get('SF_Field_API__c'), Date.valueOf(((String) value).substring(0, 10)));
                            } else if (value != null) {
                                record.put(mapping.get('SF_Field_API__c'), value);
                            }
                        }
                    }
                    
                    record.LastSyncTime__c = Datetime.now();
                    record.Account__c = crmId;
                    record.Billing_Account_Unique_Key__c = (String) data.get('ViewKey');
                    
                    recordsToUpsert.add(record);
                    
                    
                } catch (Exception ex) {
                    invalidRows.add(data);
                    
                }
            }
            
            if (!invalidRows.isEmpty()) {
                system.debug('invalidRows: ' + invalidRows.size());
                system.debug('invalid rows:'+ JSON.serialize(invalidRows));

                createLog('Invalid Data in API Response', errorMessage, 'Inbound', JSON.serializePretty(invalidRows));
            }
            
            if (!recordsToUpsert.isEmpty()) {
                system.debug('recordsToUpsert: ' + JSON.serialize(recordsToUpsert));
                
                upsertRecords(recordsToUpsert);
            }
            
            if (endIndex < apiResponse.size() && !Test.isRunningTest()) {
                System.enqueueJob(new BillingAccountQueueable(apiResponse, endIndex, fieldMappings));
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
            if (response.getStatusCode() == 200) {
                return (List<Object>) JSON.deserializeUntyped(response.getBody());
            } else {
                createLog('API Call Failure', 'API call failed with status code: ' + response.getStatusCode(), 'Inbound',null);
            }
        } catch (Exception ex) {
            createLog('API Call Exception', ex.getMessage(), 'Inbound', null);
        }
        return new List<Object>();
    }
    
    private void upsertRecords(List<Billing_Account__c> records) {
        List<Billing_Account__c> failedRecords = new List<Billing_Account__c>();
        String errorDetails = ''; // Initialize as an empty string
        List<Billing_Account__c> filteredRecords = new List<Billing_Account__c>();
        for (Billing_Account__c record : records) {
            if (!String.isBlank(record.Billing_Account_Unique_Key__c)) {
                filteredRecords.add(record);
            } else {
                System.debug('Skipping record with blank Billing_Account_Unique_Key__c: ' + JSON.serializePretty(record));
            }
        }
        
        System.debug('Filtered records for upsert: ' + JSON.serializePretty(filteredRecords));
        if (!filteredRecords.isEmpty()) {
            try {
                Database.UpsertResult[] results = Database.upsert(
                    filteredRecords,
                Billing_Account__c.fields.Billing_Account_Unique_Key__c,
                false
                    );
                
                // Handle results
                for (Integer i = 0; i < results.size(); i++) {
                    if (!results[i].isSuccess()) {
                        for (Database.Error error : results[i].getErrors()) {
                            failedRecords.add(filteredRecords[i]);
                            errorDetails += 'Failed Record: ' + JSON.serializePretty(filteredRecords[i].Billing_Account_Unique_Key__c) + ', Error: ' + error.getMessage() + '\n';
                            System.debug('Failed Record: ' + JSON.serializePretty(filteredRecords[i]) + ', Error: ' + error.getMessage());
                        }
                    }
                }
            } catch (Exception ex) {
                System.debug('DML Exception: ' + ex.getMessage());
                createLog('DML Exception', ex.getMessage(), 'Inbound', null);
            }
        } else {
            System.debug('No valid records to upsert.');
        }
        if (!failedRecords.isEmpty()) {
            createLog('DML Failure', errorDetails, 'Inbound', JSON.serializePretty(failedRecords));
        }
    }
    
    
    
    private void createLog(String errorType, String errorMessage, String direction, String jsonData) {
        // Salesforce long text area fields allow up to 131,072 characters. Adjust to fit within a safe margin.
        Integer maxFieldLength = 130000;
        
        // Truncate JSON data if necessary
        String truncatedJson = jsonData != null && jsonData.length() > maxFieldLength
            ? jsonData.substring(0, maxFieldLength - 3) + '...'
            : jsonData;
        
        // Truncate error message if necessary
        String truncatedErrorMessage = errorMessage != null && errorMessage.length() > maxFieldLength
            ? errorMessage.substring(0, maxFieldLength - 3) + '...'
            : errorMessage;
        
        // Debugging to confirm truncation logic
        System.debug('Truncated JSON Length: ' + (truncatedJson != null ? truncatedJson.length() : 0));
        System.debug('Truncated Error Message Length: ' + (truncatedErrorMessage != null ? truncatedErrorMessage.length() : 0));
        
        // Create the log record
        Log__c log = new Log__c();
        log.Error__c = errorType + ': ' + truncatedErrorMessage;
        log.Direction__c = direction;
        log.Json__c = truncatedJson;
        system.debug('log.Error__c: '+ log.Error__c+'log.Json__c: '+ log.Json__c);
        // Insert log and handle potential errors
        try {
            insert log;
        } catch (Exception e) {
            System.debug('Failed to insert log: ' + e.getMessage());
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