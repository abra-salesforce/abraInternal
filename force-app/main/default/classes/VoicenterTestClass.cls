@isTest
private class VoicenterTestClass {
       
     static void validateContact()
    {
        //create contact, lead , account;
        //each with diffrent number
        List<String> searchResultsIds = new List<String>();
        Contact contact1 = new Contact(LastName = 'TestContact1');        		        
        contact1.Phone = '0501234567';
        //contact1.Department = 'TestDepartment';
        contact1.MobilePhone = '0501234567';
        
        insert(contact1);                        
        searchResultsIds.add(contact1.Id);                
        Test.setFixedSearchResults(searchResultsIds);
        object firstRes = VoicenterLightningApexController.FindObjectByPhone('0501234567');                
        String entityId = VoicenterLightningApexController.FindIDByPhone('0501234567');
        object c2cTask1 = VoicenterLightningApexController.CreateTaskFromClick2Call('flgkaemgj',contact1.Id);
        
	}
        
    @isTest(SeeAllData = true)
    static void validateLead()
    {                
        List<String> searchResultsIds = new List<String>();       
		Lead lead1 = new Lead(LastName = 'TestLead1');                
        lead1.Company = 'Test';        
		lead1.MobilePhone = '0500000000';        
        lead1.Phone = '0500000000';
        lead1.Status = 'Open';
        insert(lead1);        
        searchResultsIds.add(lead1.Id);                
        Test.setFixedSearchResults(searchResultsIds);
        object firstRes = VoicenterLightningApexController.FindObjectByPhone('0500000000');        
        object thirdRes = VoicenterLightningApexController.FindObjectByPhone('Unknown');
        String entityId = VoicenterLightningApexController.FindIDByPhone('0500000000');
        object c2cTask1 = VoicenterLightningApexController.CreateTaskFromClick2Call('blabla',lead1.Id);
	}
    
    @isTest(SeeAllData = true)
    static void validateAccount()
    {
        //create contact, lead , account;
        //each with diffrent number
        List<String> searchResultsIds = new List<String>();
        Account account = new Account(Name = 'TestAccount');        
		account.Phone = '050123123';
        insert(account);        
        searchResultsIds.add(account.Id);        
        
        Test.setFixedSearchResults(searchResultsIds);
        object firstRes = VoicenterLightningApexController.FindObjectByPhone('050123123');
        String entityId = VoicenterLightningApexController.FindIDByPhone('050123123');
        object c2cTask1 = VoicenterLightningApexController.CreateTaskFromClick2Call('blablablabla',account.Id);
        
        
	}
    
    @isTest(SeeAllData=true)
    static  void validateVoicenter() {         
        string x =  VoicenterLightningApexController.FindIDByPhone('0501234567');
        System.assertNotEquals(x,'');
        
        
        string x1 =  VoicenterLightningApexController.FindIDByPhone('Unidentified');
        object y =  VoicenterLightningApexController.FindObjectByPhone('0500000000');
        object yx =  VoicenterLightningApexController.FindObjectByPhone('0501234567');
        object y11 =  VoicenterLightningApexController.FindObjectByPhone('');        

/*
        VoicenterLightningApexController.VoicenterCrmData crm = new VoicenterLightningApexController.VoicenterCrmData();
        crm.CustomerFieldName='WhoId';
        crm.StatusFieldValue ='Completed';
        crm.DefaultCdrOwnerID='005b0000000eXBmAAM';
        crm.DefaultCustomerFieldName='Contact';          
        VoicenterLightningApexController.VoicenterCrmData crm2 = new VoicenterLightningApexController.VoicenterCrmData();
        crm2.CustomerFieldName='dddddddd';
        crm2.StatusFieldValue ='Completed';
        crm2.DefaultCdrOwnerID='';
        crm2.DefaultCustomerFieldName='ddddd';

*/
        
        VoicenterLightningApexController.VoicenterCDR cdr = new VoicenterLightningApexController.VoicenterCDR();
        cdr.CallID ='456474567677';
        cdr.CallerExtension='qGgCG45d';
        cdr.CallerNumber='0732248111';
        cdr.DateEpoch=0;
        cdr.DialStatus='Test';
        cdr.Duration=0;
        cdr.ID=0;
        cdr.RecordURL='http://test.com/769879898';
        cdr.TargetExtension='qGgCG45d';
        cdr.TargetNumber='0523574321';
        cdr.UrlID=0;
        
//        object z=   VoicenterLightningApexController.LogCalls(crm, cdr);
//        object z2=  VoicenterLightningApexController.GetUserID( cdr,crm.DefaultCdrOwnerID);
//        object z3=  VoicenterLightningApexController.GetCustomerID( cdr,crm.DefaultCustomerFieldName);
//        object z9=   VoicenterLightningApexController.LogCalls(crm, cdr);
//        System.assertNotEquals(z9,null);
        VoicenterLightningApexController.VoicenterCDR cdr2 = new VoicenterLightningApexController.VoicenterCDR();
        cdr2.CallID ='0523574321';
        cdr2.CallerExtension='qGgCG45d';
        cdr2.CallerNumber='0523574321';
        cdr2.DateEpoch=0;
        cdr2.DialStatus='Test';
        cdr2.Duration=0;
        cdr2.ID=0;
        cdr2.RecordURL='http://test.com/769879898';
        cdr2.TargetExtension='qGgCG45d';
        cdr2.TargetNumber='0732248111';
        cdr2.UrlID=0;
        
//        object z22=   VoicenterLightningApexController.LogCalls(crm, cdr2);   
//        object z222=   VoicenterLightningApexController.LogCalls(crm2, cdr2);   

        VoicenterLightningApexController.VoicenterCDR cdr3 = new VoicenterLightningApexController.VoicenterCDR();
        cdr3.CallID ='';
        cdr3.CallerExtension='';
        cdr3.CallerNumber='';
        cdr3.DateEpoch=0;
        cdr3.DialStatus='';
        cdr3.Duration=0;
        cdr3.ID=0;
        cdr3.RecordURL='';
        cdr3.TargetExtension='';
        cdr3.TargetNumber='';
        cdr3.UrlID=0;
//        object z33=   VoicenterLightningApexController.LogCalls(crm, cdr3);
//        object z333=   VoicenterLightningApexController.LogCalls(crm2, cdr3);
//        object z39=  VoicenterLightningApexController.GetCustomerID( cdr2,crm2.DefaultCustomerFieldName);
//        object z29=  VoicenterLightningApexController.GetUserID( cdr2,crm.DefaultCdrOwnerID);
        
        object c2cTask1 = VoicenterLightningApexController.CreateTaskFromClick2Call('','003b0000011N37D');
        System.assertNotEquals(c2cTask1,null);
        object c2cTask2 = VoicenterLightningApexController.CreateTaskFromClick2Call('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx','003b0000011N37D');
        System.assertNotEquals(c2cTask2,null);
        object c2cTask3 = VoicenterLightningApexController.CreateTaskFromClick2Call('','');
        System.assertNotEquals(c2cTask3,null);
        object c2cTask4 = VoicenterLightningApexController.CreateTaskFromClick2Call('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx','');
        System.assertNotEquals(c2cTask4,null);
        object c2cTask5 = VoicenterLightningApexController.CreateTaskFromClick2Call('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx','Test');
        System.assertNotEquals(c2cTask5,null);
                
    }
    
   @isTest(SeeAllData=true)
   static void ValidateFindObjectByPhone()
    {
               
        Lead lead = new Lead(LastName = 'TestLead1');
        lead.Company = 'Bla';
		lead.MobilePhone = '0501234567';
        insert(lead);
        List<String> searchResultsLead = new List<String>();
        searchResultsLead.add(lead.Id);        
        Test.setFixedSearchResults(searchResultsLead);                     
        object objectResultLead =  VoicenterLightningApexController.FindObjectByPhone('0501234567');  
        
        Account account = new Account(Name = 'TestAcc');
        account.Phone = '0501234567';
        //account.Active__c = 'True';
		insert(account);
        List<String> searchResultsAccount = new List<String>();
        searchResultsAccount.add(account.Id);        
        Test.setFixedSearchResults(searchResultsAccount);                     
        object objectResultAccount =  VoicenterLightningApexController.FindObjectByPhone('0501234567');  

        
        Contact contact = new Contact(LastName = 'TestContact1');
		contact.MobilePhone = '0501234567'; 
        contact.Phone = '0501234567';
        //contact.Department = 'TestDep';
        insert(contact);
        List<String> searchResultsContact = new List<String>();
        searchResultsContact.add(contact.Id);
        Test.setFixedSearchResults(searchResultsContact);      
		object objectResultContact =  VoicenterLightningApexController.FindObjectByPhone('0501234567');                
    }
}