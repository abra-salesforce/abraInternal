/**
 * @ Author: Your name
 * @ Create Time: 2020-09-16 13:23:47
 * @ Modified by: ZedXagE
 * @ Modified time: 2021-03-19 20:08:11
 * @ Description:
 */

@RestResource(urlMapping='/licenseService')
global without sharing class LicenseService {
    @HttpPost
    global static license checkLic() {
        return checkLic(RestContext.request.requestBody.toString());
    }
    global static license checkLic(String licJson) {
        return checkLic((license)JSON.deserialize(licJson, license.class),true);
    }
    global static license checkLic(License lic,Boolean fTry) {
        if(lic.orgId!=null&&lic.product!=null){
            List <License__c> lics = [select CreatedDate,Quantity__c,Active__c,Type__c,Start_Date__c,End_Date__c from License__c where Organization_Id__c=:lic.orgId and Product__c=:lic.product Order by CreatedDate DESC limit 1];
            if(lics.size()>0){
                lic.endDate = lics[0].End_Date__c;
                lic.startDate = lics[0].Start_Date__c;
                lic.quantity = lics[0].Quantity__c;
                lic.type = lics[0].Type__c;
            } else if(fTry){
                //new install
                lic.isSandbox = lic.isSandbox==true?true:false;
                License__c lic4ins = new License__c(Start_Date__c=System.Today(),Product__c=lic.product,Organization_Id__c=lic.orgId,Organization_Name__c=lic.orgName,End_Date__c=System.Today().addDays(30),Type__c='Trial',Is_Sandbox__c=lic.isSandbox);
                insert lic4ins;
                try{
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(new String[] {'edan@itmyway.com'});
                    mail.setSenderDisplayName('License Service'+lic.product);
                    mail.setSubject('New '+lic.product+' install');
                    mail.setHtmlBody('<a href="https://itmyway.lightning.force.com/'+lic4ins.id+'">record link</a>');
                    if(!Test.isRunningTest())   Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                }
                catch(exception e){}
                return checkLic(lic,false);
            }
        }
        return lic;
    }
    global class license {
        public String orgId;
        public String orgName;
        public Boolean isSandbox;
        public String product;
        public String type;
        public Date endDate;
        public Date startDate;
        public Decimal quantity;
    }    
}