@isTest(seealldata=true)
public class OppAndScopeTest {
    public static testMethod void tes() {
        Opportunity opp = [select id,CreatedDate,Accountid from Opportunity where StageName!='Closed Won' and accountid!=null and Ownerid=:Userinfo.getUserId() Order by CreatedDate desc limit 1];
        Scope_Template__c st = new Scope_Template__c(Category__c='Sales',Name='test',Scope_Info__c='test',Default_PM_Budget__c=120,Default_Implementation_Budget__c=120,Default_Dev_Budget__c=120,Default_QA_Budget__c=120);
        insert st;
        insert new Project_Milestone__c(Scope_Template__c=st.id,Days_from_Start__c=3,Recurring__c='Week',Recurring_Interval__c=1);
        insert new Project_Milestone__c(Scope_Template__c=st.id,Days_from_Start__c=3);
        insert new Project_Milestone__c(Scope_Template__c=st.id);
        Project__c proj = TestsUtil.createMeP(opp.Accountid);
        insert proj;
        insert new Scope_Item__c(Opportunity__c=opp.id,Project__c=proj.id,Scope_Template__c=st.id,Start_Date__c=System.Today(),End_Date__c=System.Today().addDays(60));
        proj.Start_Date__c = System.Today();
        proj.Due_Date__c = System.Today().addMonths(3);
        proj.Scope_Template__c = st.id;
        update proj;
        test.startTest();
        opp.StageName = 'Closed Won';
        try{
            update opp;
        }catch(exception e){}
        test.stopTest();
    }
    public static testMethod void testUtilTests() {
        String recTypeIdSalesforce = [select id from RecordType Where SobjectType='Working_Hours__c' and Name='Salesforce' limit 1].id;
        String conId = [select id from Contact where name='Edan Badani' limit 1].id;
        Opportunity opp = [select id,CreatedDate,Accountid from Opportunity where StageName!='Closed Won' and accountid!=null Order by CreatedDate desc limit 1];
        Project__c proj = TestsUtil.createMeP(opp.Accountid);
        insert proj;
        Working_Days__c w1 = TestsUtil.createMeWD(conId, Datetime.newInstance(2025, 11, 17), 'Work', null, null);
        insert w1;
        update new Working_Days__c(Id=w1.Id, Start__c = Datetime.newInstance(2025, 10, 17)); 
        Scope_Item__c si = TestsUtil.createMeSI(proj.id);
        insert si;
        Working_Hours__c wH1 = TestsUtil.createMeWH(recTypeIdSalesforce, conId, proj.Account__c, proj.id, si.Id, Date.newInstance(2025, 11, 17), 4, 'Non-Billable hours - Administration', null, null);
        insert wH1;
        Project__c proj2 = TestsUtil.createMeP();
        insert proj2;
        new MonthlyController().execute(null);
        upsert new Monthly_Teken__c(Date__c=Date.newInstance(2025, 01, 01),Teken__c=180, Key__c=String.valueOf(Date.newInstance(2025, 01, 01))) Key__c;
        Test.startTest();
		Monthly_Hours__c m = MonthlyController.createMonthly(conId, Date.newInstance(2025, 01, 01), null);
        upsert m Key__c;
        update m;
        insert new Holiday__c(Date__c=Date.newInstance(2025, 11, 11), Half_Day__c=false, Muslim_Holiday__c=false);
        insert new Holiday__c(Date__c=Date.newInstance(2025, 11, 11), Half_Day__c=true, Muslim_Holiday__c=false);
        insert new Holiday__c(Date__c=Date.newInstance(2025, 11, 11), Half_Day__c=false, Muslim_Holiday__c=true);
        Test.stopTest();
    }
}