public class currentContact {
  @AuraEnabled
  public static String getContact() {
      List<contact> con=[select id from contact where name=:userinfo.getName() limit 1];
      if(con.size()>0)
    	  return con[0].id;
      else
        return null;
  }
  @AuraEnabled
  public static Contact getContactRecord() {
      List<contact> con=[select id,Employee_type__c from contact where name=:userinfo.getName() limit 1];
      if(con.size()>0)
    	  return con[0];
      else
        return null;
  }
    @AuraEnabled
  public static String getAccountProject(String curid) {
      List<issue__c> iss=[select account_name__c,project__c from issue__c where id=:curid limit 1];
      if(iss.size()>0)
    	  return iss[0].account_name__c+';'+iss[0].project__c;
      else
        return null;
  }
 }