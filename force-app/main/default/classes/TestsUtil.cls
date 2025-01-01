public with sharing class TestsUtil {
    public static Working_Days__c createMeWD(Id conId, Datetime dT, String type, String monthlyId, Id weeklyId){
        Working_Days__c resWD = new Working_Days__c(
            Performed_By_contact__c = conId,
            Start__c = dT,
            Type__c = type,
            Monthly_Hours__c = monthlyId,
            Weekly_Hours__c = weeklyId
        );
        return resWD;
    }

    public static Working_Hours__c createMeWH(String recType, String conId, String accId, String projectId, String scopeId, Date d, Integer numOfH, String descrip, Id monthlyId, Id weeklyId){
        if(Test.isRunningTest()&&projectId==null){
            Scope_Item__c sc = getScopeTest();
            accId = sc.Project__r.Account__c;
            projectId = sc.Project__c;
            scopeId = sc.Id;
        }
        Working_Hours__c resM = new Working_Hours__c(
            RecordTypeId = recType,
            Performed_By_2__c = conId, 
            Account__c = accId,
            Project__c = projectId,
            Scope_Item__c = scopeId,
            Date__c = d,
            Number_Of_Hours__c = numOfH, 
            Monthly_Hours__c = monthlyId,
            Weekly_Hours__c = weeklyId,
            Description_Of_Work__c = descrip
        );
        return resM;
    }

    public static Project__c createProject(Project__c parentProject){
        Pricebook2 pB = new Pricebook2();
        pB.Name = 'price Book test'; insert pB;
        Project__c project = new Project__c();
        project.recordTypeId = [select id from RecordType where SobjectType='Project__c' and Name='Salesforce'].Id;
        project.Name = 'Sales';
        project.Status__c = 'Active';
        project.Account__c = parentProject.Account__c;
        project.Billing_Type__c = 'Hourly';
        project.Price_Book__c = pB.Id;
        project.Parent_Project__c = parentProject.Id;
        insert project;
        System.debug('Project: ' + project);
        return project;
    }

    /*public static Resource_Planning_Per_Week__c createMeRP(String pTPWId, String weeklyId, Integer amountOfHours){
        Resource_Planning_Per_Week__c res =  new Resource_Planning_Per_Week__c(
            Planned_Time_Per_Week__c = pTPWId,
            Weekly_Hours__c = weeklyId,
            Hours_Assigned__c = amountOfHours
        );
        return res; 
    }*/

    public static Scope_Item__c createMeSI(String pid){
        Scope_Item__c res = new Scope_Item__c(
            Name = 'sTest',
            Project__c = pid,
            /*Budget__c = 70,*/
            Start_Date__c = System.Today(),
            End_Date__c = System.Today().addDays(10)
        );
        return res;
    }

    public static Project__c createMeP(){
        Account accTest = [select id from account limit 1];
        Pricebook2 pbTest = new Pricebook2(Name = 'pBTest');
        insert pbTest;
        String recTypeSalesForce = '012b00000001A8FAAU';
        Project__c res = new Project__c(
            RecordTypeId = recTypeSalesForce,
            Name = 'Sales',
            Status__c = 'Active',
            Account__c = accTest.Id ,
            Billing_Type__c = 'Hourly',
            Price_Book__c = pbTest.Id
        );
        return res;
    }
    public static Project__c createMeP(String accid){
        Pricebook2 pbTest = new Pricebook2(Name = 'pBTest');
        insert pbTest;
        String recTypeSalesForce = '012b00000001A8FAAU';
        Project__c res = new Project__c(
            RecordTypeId = recTypeSalesForce,
            Name = 'Sales',
            Status__c = 'Active',
            Account__c = accid ,
            Billing_Type__c = 'Hourly',
            Price_Book__c = pbTest.Id
        );
        return res;
    }

    /*public static Planned_Time_Per_Week__c createMePTPR(String givenName, String scopeItemId, Date sDate, Integer amountOfHours){
        Planned_Time_Per_Week__c res = new Planned_Time_Per_Week__c(
            Scope_Item__c = scopeItemId,
            Start_date__c = sDate,
            Budget__c = amountOfHours
        );
        return res;
    }*/

    public static Working_Team_Resource__c createMeWTR(String conId, String wtid){
        Working_Team_Resource__c res = new Working_Team_Resource__c(Contact__c = conId,Team_Member_Type__c = 'Developer',Working_Team__c = wtid);
        return res;
    }

    public static  Scope_item__c getScopeTest(){
        return [select id,Project__r.Account__c,Project__c,Project__r.Parent_Project__c from Scope_item__c where Project__r.Account__r.Name!='ITmyWay' and Project__r.RecordType.Name!='Salesforce Master' and Project__r.Status__c!='Completed' and Project__r.Project_Number__c!=null limit 1];
    }
}