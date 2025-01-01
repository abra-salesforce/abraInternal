@isTest(seealldata=true)
public class WorkerAssistantTest {
    static testMethod void tes() {
        update new User(id=Userinfo.getUserId(),Worker_Assistant__c='Assigner');
        WorkerAssistantController.getInit(Userinfo.getUserId());
        String isid = [select id from Issue__c where Assigned_To__c!=:Userinfo.getUserId() and Scope_item__c!=null and Login_Details_1__c!=null and Deploy_Login_Details__c!=null limit 1].id;
        WorkerAssistantController.getContentDocs(isid);
        WorkerAssistantController.isRunning(isid,true);
        WorkerAssistantController.changeStatus(isid,'New',null);
        WorkerAssistantController.cfile fl = new WorkerAssistantController.cfile(new ContentDocumentLink());
        WorkerAssistantController.saveWD(JSON.serialize(new Working_Days__c(Performed_By_contact__c=[select id from Contact where name='Edan Badani' limit 1].id,Start__c=System.Now().addDays(46),End__c=System.Now().addHours(1).addDays(46))));
        update new Working_Hours__c(id=[select id,CreatedDate from Working_Hours__c Order by CreatedDate desc limit 1].id,Description_of_Work__c='testing Zed');
        try{
            WorkerAssistantController.saveWAS(JSON.serialize(new List<WorkerAssistantController.wa>{new WorkerAssistantController.wa([select id,CreatedDate,Description_Of_Work__c,Name,Project__c,Project__r.Name,Number_Of_Hours__c,Billable_Hours__c,Issue__c,Issue__r.Name from Working_Hours__c where Scope_item__c!=null limit 1])}));
        } catch(exception e){}
        try{
            WorkerAssistantController.deleteWA([select id from Working_Hours__c where Scope_item__c!=null limit 1].id);
        } catch(exception e){}
        try{
            update new Issue__c(id=isid,Assigned_To__c=Userinfo.getUserId());
        } catch(exception e){}
        try{
            WorkerAssistantController.saveFeedView(isid);
        } catch(exception e){}
        try{
            WorkerAssistantController.markProgress(isid);
        } catch(exception e){}
        try{
            WorkerAssistantController.reOrder(Userinfo.getUserId(),isid,1);
        } catch(exception e){}
    }
}