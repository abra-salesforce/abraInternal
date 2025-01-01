public with sharing class DeleteOldWHFFromNavIntHelper {
    @future(callout=true)
    public static void deleteWH(Map<String,String> contactIdbyNavId){
        Nav_Setting__mdt sett = AsyncNavIntegrationQueueable.getSettings();
        Map <String,Contact> contactsMap = new Map<String,Contact>([select id,Email from Contact where id in:contactIdbyNavId.values()]);
        for(String navId : contactIdbyNavId.keySet())
            calloutToDeleteToAbra(navId, contactsMap.get(contactIdbyNavId.get(navId)).Email, sett);
    }
    public static void calloutToDeleteToAbra(String curNavId, String curUserName, Nav_Setting__mdt sett){
        //Set HTTPRequest Method
        HttpRequest req = new HttpRequest();
        req.setTimeout(120000);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('ApiKey', sett.Api_Key__c);
        req.setEndpoint(sett.Endpoint__c+'/v1/DeleteOneTimesheet/ITmyway/'+curUserName);
        // setting body
        System.debug('Input Request:' + '{"id":"'+curNavId+'"}');
        req.setBody('{"id":"'+curNavId+'"}');
        //Execute web service call here     
        Http http = new Http();
        HTTPResponse res = new HTTPResponse();
        if(!Test.isRunningTest())   res = http.send(req);
        //Helpful debug messages
        System.debug(res.toString());
        System.debug('STATUS:' + res.getStatus());
        System.debug('STATUS_CODE:' + res.getStatusCode());
        String responseXML = res.getBody();
        System.debug('responseXML:' + responseXML);
        Integer statusCode = res.getStatusCode();
    }
}