public class StoreController {
	public Lead lead {get;set;}
	public StoreController() {
		lead=new Lead(newsletter__c=false,Type__c='Customer',Terms__c=false);
	}
	public void saveLead(){
		insert lead;
		/*try{
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			mail.setToAddresses(new String[] {lead.Email});
			mail.setSenderDisplayName('ITmyWay Apps');
			mail.setSubject('Here is your Download link');
			mail.setHtmlBody([select Download__C from Store_Products__c where Name=:Lead.LeadSource].Download__c);
			if(!Test.isRunningTest())
				Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
		}
		catch(exception e){}*/
		lead=new Lead(FirstName=lead.FirstName,LastName=lead.LastName,Company=lead.Company,Email=lead.Email,Phone=lead.Phone,newsletter__c=false,Type__c='Customer',Terms__c=false,CountryCode=lead.CountryCode);
	}
}