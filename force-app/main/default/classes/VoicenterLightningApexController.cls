public with sharing class VoicenterLightningApexController {    
    
    public class VoicenterCdrInsertResult {
        public object InsertResult { get; set; }
        public VoicenterCDR CDR { get; set; }
        public String Error { get; set; }
        public String WorkerID { get; set; }
        public String CustomerID { get; set; }
        public String ExistingTaskOID  { get; set; }
    }
    
    public class FindObjectResponse {
        public String ID { get; set; }
        public String Name { get; set; }
        public String OrganizationName { get; set; }
        public String ObjectType { get; set; }
        public String Phone {get;set;}
        public object Raw {get;set;}
    } 
    
    public class VoicenterCDR {
        public string CallID  { get; set; }
        public string CallerExtension { get; set; }
        public string CallerNumber { get; set; }
        public Long DateEpoch { get; set; }
        public string DialStatus { get; set; }
        public integer Duration { get; set; }
        public integer ID { get; set; }
        public string RecordURL { get; set; }
        public string TargetExtension { get; set; }
        public string TargetNumber { get; set; }
        public integer UrlID { get; set; }
    }
    
    @AuraEnabled
    public static Task GetTaskDB(String paramID) {
        return [SELECT Id
                FROM Task
                WHERE Id =: paramID];
    } 
    
    @AuraEnabled
    public static String FindObjectByPhone(String phoneNumber) {       
        
        String phoneNumbers = '';
        if(phoneNumber.startsWith('972'))
        {
             phoneNumbers =  phoneNumber + ' OR ' + phoneNumber.replaceFirst('972', '0');
        }
        else
        {
            phoneNumbers = phoneNumber;
        }
        List<List<sObject>> results = [FIND :phoneNumbers
                                       IN Phone FIELDS
                                       RETURNING 
                                       Contact(Id, Phone, Name, Department),
                                       Account(Id, Phone, Name), 
                                       Lead(Id, Phone, Company, Name)];
        
        Boolean foundResult = false;
        //If you want to change the default entity change this parameter to one of the values : 'Contact' / 'Lead' / 'Account'         
        FindObjectResponse resp = new FindObjectResponse();
        resp.Raw = results;
        resp.Phone = phoneNumber;
        if(ValidateNumber(phoneNumber))
        {
            if(results[0].size() > 0) {
                Contact cny = (Contact)results[0][0];
                resp.ID = cny.Id;
                resp.Name = cny.Name;
                resp.OrganizationName = cny.Department;
                resp.ObjectType = 'Contact';
                foundResult = true;
            }
            else if(results[1].size() > 0) {
                Account accnt = (Account)results[1][0];
                resp.ID = accnt.Id;
                resp.Name = accnt.Name;
                resp.OrganizationName = accnt.Name;
                resp.ObjectType = 'Account';
                foundResult = true;
            }
            else if(results[2].size() > 0) {
                Lead lny = (Lead)results[2][0];
                resp.ID = lny.Id;
                resp.Name = lny.Name;
                resp.OrganizationName = lny.Company;
                resp.ObjectType = 'Lead';
                foundResult = true;
            }
            if(!foundResult)
            {
                FindObjectResponse defaultEntity = GetDefaultEntity();
                if(defaultEntity != null)
                {
                    resp.ID = defaultEntity.Id;                    
                    resp.Name = defaultEntity.Name;                  
                    resp.OrganizationName = defaultEntity.OrganizationName;                   
                    resp.ObjectType = defaultEntity.ObjectType;
                }           
                else
                {
                    //Can create a random Lead / Contact ? 
                    //This might do some problems with diffrent integrations , 
                    //can add a checkbox for "Create new lead when no results found" 
                }
            }              
        }
        
        /*
sObject[] records = ((List<sObject>)results[0]);
if (!records.isEmpty()) {
for (Integer i = 0; i < records.size(); i++) {
sObject record = records[i];   
if (record.getSObjectType() == Contact.getSObjectType()) {
// contacts.add((Contact) record);
//return ((String)((Contact) record).Id);
Contact cny = (Contact) record;
resp.ID = cny.Id;
resp.Name = cny.Name;
resp.OrganizationName = cny.Department;
resp.ObjectType = 'Contact';
}
else if (record.getSObjectType() == Lead.getSObjectType()){
//leads.add((Lead) record);
//return ((String)((Lead) record).Id);
Lead lny = (Lead) record;
resp.ID = lny.Id;
resp.Name = lny.Name;
resp.OrganizationName = lny.Company;
resp.ObjectType = 'Lead';
} 
else if (record.getSObjectType() == Account.getSObjectType()){
Account accnt = (Account)record;
resp.ID = accnt.Id;
resp.Name = accnt.Name;
resp.OrganizationName = accnt.Name;
resp.ObjectType = 'Account';
}
}
}*/
        String srt = JSON.serialize(resp);
        return srt;
        //return resp.ID;
        //return String.valueOf(results[0].size());
    }
    
    //Short numbers logic, validate that a number is longer then 6 digit / anonymous
    public static Boolean ValidateNumber(String phoneNumber)
    {
        phoneNumber = phoneNumber.deleteWhitespace();
        Boolean validPhoneNumber = false;
        if(phoneNumber.length() > 6)
        {   
            if(phoneNumber.isNumeric() == true)
            {
                validPhoneNumber = true;
            }
            else
            {
                if(phoneNumber.equalsIgnoreCase('private') ||  
                   phoneNumber.equalsIgnoreCase('anonymous') ||
                   phoneNumber.equalsIgnoreCase('restricted') ||
                   phoneNumber.equalsIgnoreCase('unknown') )
                {
                    validPhoneNumber = true;
                }                   
            }            
        }        
        return validPhoneNumber;
    }
    
    @AuraEnabled
    public static String CreateTaskFromClick2Call(String ivrUniqueID, String customerID){
        // Check if task with given Ivr unique id already exists:
        VoicenterCdrInsertResult res = new VoicenterCdrInsertResult();
        // Avilable types are Task / Entity / None 
        // Need to define the Popup type in the metadate configuration "Voicenter Configuration"
        // Default Value is Task.
        String popupType = 'Task';
        SObject popupTypeObject = null;
        SObject entity = null;
        try
        {
            popupTypeObject = GetValueFromConfiguration('Popup_Type__c', 'Voicenter_Configuration__mdt', '');
            if(popupTypeObject != null)
            {
                popupType = (String)popupTypeObject.get('Popup_Type__c');
            }
        }
        // need to decide what to do here..     
        catch(Exception ex)
        {
            //Need to write the code here.. 
        }
        res.Error = 'OK';
        res.WorkerID = '';
        res.CustomerID = '';
        res.ExistingTaskOID = '';    
        ivrUniqueID = ivrUniqueID.trim();    
        if(ivrUniqueID == '')
        {
            res.Error = 'Empty ivr id';
            return (String)JSON.serialize(res);
        }
        
        /*List<List<sObject>> results = [FIND :ivrUniqueID
IN ALL FIELDS
RETURNING 
Task(Id)];

if(results[0].size() > 0) {
res.Error = 'Already exists';
Task task = (Task)results[0][0];
res.ExistingTaskOID = task.Id;
return res;
}*/
        
        try{
            Task t = new Task(
                OwnerId = UserInfo.getUserId(),
                Subject = 'Call',
                Status = 'Open',
                Priority = 'Normal',
                ivruniqueid__c = ivrUniqueID
            );
            
            //Contact and Lead count as Whoid the rest count as WhatId 
            //Might need to add values for specific clients that use Custom Objects
           if(customerID != null && customerID != '')
           {
                if(customerID.startsWith('003')|| customerID.startsWith('00Q')){
                t.Whoid = customerID;
            }
            else {
                t.WhatId = customerID;
            }
           }
                
            upsert t;
            if(popupType == 'Entity')
            {
                entity = GetEntity(customerID);
                if(entity != null)
                {
                    res.InsertResult = entity;                
                }
            }                                
            else if(popupType == 'Task')
            {
                res.InsertResult = t;
            }
            else if(popupType == 'None')
            {
                res.CustomerID = 'NoPopup';
            }          
        }
        catch(DmlException e) {
            res.InsertResult = e.getMessage();
            res.Error = 'Dml Error';
            String em =  e.getMessage();
            //   System.debug('The following exception has occurred: ' + em );    
            //return em;
        }
        
        catch (Exception e) {
            res.InsertResult = e.getMessage();
            res.Error = 'Error';
            //  System.debug('Query Issue: ' + e);  //return e.getMessage();
        }
        String srt = JSON.serialize(res);
        return srt;
    }
    
    @AuraEnabled
    public static String FindIDByPhone(String phoneNumber) {
        List<List<sObject>> results = [FIND :phoneNumber
                                       IN Phone FIELDS
                                       RETURNING Contact(Id, Phone, FirstName, LastName),
                                       Lead(Id, Phone, FirstName, LastName), Account(Id, Phone, Name)];
        sObject[] records = ((List<sObject>)results[0]);
        
        //return 'in FindIdByPhone';
        
        if (!records.isEmpty()) {
            for (Integer i = 0; i < records.size(); i++) {
                sObject record = records[i];   
                
                
                if (record.getSObjectType() == Contact.sObjectType) {
                    // contacts.add((Contact) record);
                    
                    return ((String)((Contact) record).Id);
                }
                else if (record.getSObjectType() == Lead.sObjectType){
                    //leads.add((Lead) record);
                    return ((String)((Lead) record).Id);
                }
                else if (record.getSObjectType() == Account.sObjectType){
                    //leads.add((Lead) record);
                    return ((String)((Lead) record).Id);
                }
            }
        }   
        return null;
    }
    
    // Get Default entity id from metadata
    // Get the entity that was in the metadata    
    @AuraEnabled
    public static FindObjectResponse GetDefaultEntity()
    {
        SObject result = GetValueFromConfiguration('Default_Entity_Id__c', 'Voicenter_Configuration__mdt', ' ');
        String defaultEntityId = (String)result.get('Default_Entity_Id__c');             
        FindObjectResponse defaultEntityDetails = null;
        SObject entity = GetEntity(defaultEntityId);
        if(entity != null)
        {
            defaultEntityDetails = new FindObjectResponse();
            if(defaultEntityId.startsWith('003')) 
            {
                Contact cny = (Contact)entity;
                defaultEntityDetails.ID = cny.Id;
                defaultEntityDetails.Name = cny.Name;
                defaultEntityDetails.OrganizationName = cny.Department;
                defaultEntityDetails.ObjectType = 'Contact';                
            }
            else if(defaultEntityId.startsWith('001')) {
                Account accnt = (Account)entity;
                defaultEntityDetails.ID = accnt.Id;
                defaultEntityDetails.Name = accnt.Name;
                defaultEntityDetails.OrganizationName = accnt.Name;
                defaultEntityDetails.ObjectType = 'Account';                          
            }
            else if(defaultEntityId.startsWith('00Q')) {
                Lead lny = (Lead)entity;
                defaultEntityDetails.ID = lny.Id;
                defaultEntityDetails.Name = lny.Name;
                defaultEntityDetails.OrganizationName = lny.Company;
                defaultEntityDetails.ObjectType = 'Lead';                
            }            
        }
        
        return defaultEntityDetails;
    }    
    
    // Query helper to get entitys from database instead of using the piece of code everywhere
    @AuraEnabled 
    public static SObject GetEntity(String entityId)
    {
        SObject result = null;
        List<SObject> results;
        if(entityId != null && entityId != '')
        {
            if(entityId.startsWith('001'))
            {
                results =  [SELECT Id,Phone, Name FROM Account Where Id = :entityId LIMIT 1];     
                
            }
            else if(entityId.startsWith('003'))
            {
                results = [SELECT Id,Phone,Name,Department FROM Contact Where Id = :entityId LIMIT 1];
            }
            else if(entityId.startsWith('00Q'))
            {
                results = [SELECT Id,Phone, Name, Company FROM Lead Where Id = :entityId LIMIT 1];
            }    
            
            if(results != null && results.size() > 0)
            {
                result = results[0];
            }
        }
        
        return result;
    }
    
    @AuraEnabled
    public static SObject GetValueFromConfiguration(String fieldName, String metadataName, String whereClause)
    {
        //Custom metadata object - Voicenter_Configuration__mdt 
        //Contains : 
        //Popup_Type__c
        //Default_Entity_Id__c
        //
        //
        List<SObject> result;
        SObject value = null;
        String query = 'SELECT ' + fieldName + ' FROM ' + MetadataName + ' ';
        result = Database.query(query);
        if(result != null && result.size() > 0)
        {
            value = result[0];
        }
        
        return value;
    }        
}