@isTest
private class RivhitIntegrationTest {
    static testMethod void testMe() {
        insert new Account(Name='String content', Finance_Acct_num__c='2147483647');

        RivhitIntegration.scheduleAndExecute();

        System.debug('test:AccountBalance');
        System.debug([SELECT Id FROM Account WHERE Finance_Acct_num__c!=null]);
        RivhitIntegration.AccountBalanceTestable(new List<Id>(new Map<Id, Account>([SELECT Id FROM Account WHERE Finance_Acct_num__c!=null]).keySet()), new List<String>(), new List<String>(), null, null);
        RivhitIntegration.AccountBalanceTestable(new List<Id>(), new List<String>(), new List<String>(), null, null);

        System.debug('test:Invoices');
        RivhitIntegration.InvoicesTestable(null, null);

        System.debug('test:InvoicesStatuses');
        System.debug([SELECT Id FROM Account WHERE Finance_Acct_num__c!=null]);
        RivhitIntegration.InvoicesStatusesTestable(new List<Id>(new Map<Id, Account>([SELECT Id FROM Account WHERE Finance_Acct_num__c!=null]).keySet()), new List<String>(), new List<String>());
        RivhitIntegration.InvoicesStatusesTestable(new List<Id>(), new List<String>(), new List<String>());

        System.debug('test:InvoiceDetails');
        System.debug([SELECT Id FROM Invoice__c WHERE Total_Amount__c=null]);
        RivhitIntegration.InvoiceDetailsTestable(new List<Id>(new Map<Id, Invoice__c>([SELECT Id FROM Invoice__c WHERE Total_Amount__c=null]).keySet()), new List<String>(), new List<String>());
        RivhitIntegration.InvoiceDetailsTestable(new List<Id>(), new List<String>(), new List<String>());

        System.debug('test:InvoiceLineDetails');
        System.debug([SELECT Id FROM Invoice_Line__c WHERE item_group_id__c=null]);
        RivhitIntegration.InvoiceLineDetailsTestable(new List<Id>(new Map<Id, Invoice_Line__c>([SELECT Id FROM Invoice_Line__c WHERE item_group_id__c=null]).keySet()), new List<String>(), new List<String>());
        RivhitIntegration.InvoiceLineDetailsTestable(new List<Id>(), new List<String>(), new List<String>());
    }
}