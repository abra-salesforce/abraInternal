global class BillingAccountQueueable implements Queueable, Database.AllowsCallouts {
    private static final Integer chunkSize = 200;
    private List<Object> apiResponse;
    private Map<String, Map<String, String>> fieldMappings;
    private Integer startIndex;
    
    public BillingAccountQueueable() {
        this.apiResponse = new List<Object>();
        this.startIndex = 0;
    }
    
    public BillingAccountQueueable(List<Object> apiResponse, Integer startIndex, Map<String, Map<String, String>> fieldMappings) {
        this.apiResponse = apiResponse;
        this.startIndex = startIndex;
        this.fieldMappings = fieldMappings;
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
                    if (String.isEmpty(crmId) || !crmId.startsWith('001') || crmId.length() != 18) {
                        invalidRows.add(data);
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
                    /*record.Account__c = crmId;
                    if (data.containsKey('ViewKey')) {
                        record.Billing_Account_Unique_Key__c = (String) data.get('ViewKey');
                    }*/
                    
                    recordsToUpsert.add(record);
                } catch (Exception ex) {
                    invalidRows.add(data);
                }
            }
            
            if (!invalidRows.isEmpty()) {
                createLog('Invalid Data in API Response', '', 'Inbound', JSON.serialize(invalidRows));
            }
            
            if (!recordsToUpsert.isEmpty()) {
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
        try {
            Database.UpsertResult[] results = Database.upsert(records, Billing_Account__c.fields.Billing_Account_Unique_Key__c, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    failedRecords.add(records[i]);
                }
            }
        } catch (Exception ex) {
            createLog('DML Exception', ex.getMessage(), 'Inbound', JSON.serialize(records));
            return;
        }
        
        if (!failedRecords.isEmpty()) {
            createLog('DML Failure', 'One or more records failed during upsert operation.', 'Inbound', JSON.serialize(failedRecords));
        }
    }
    
    private void createLog(String errorType, String errorMessage, String direction, String jsonData) {
        String truncatedJson = jsonData;
        if (jsonData != null && jsonData.length() > 255) {
            truncatedJson = jsonData.substring(0, 252) + '...';
        }
        
        Log__c log = new Log__c();
        log.Error__c = errorType + ': ' + errorMessage;
        log.Direction__c = direction;
        log.Json__c = truncatedJson;
        insert log;
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