global class RivhitIntegration implements Schedulable {
    private class RivhitException extends Exception {}
    private static string api_token = 'E6C83A39-E7A2-48C5-B414-68B1DFE659F0';

    public static void scheduleAndExecute() { scheduleAndExecute(null, null); }
    public static void scheduleAndExecute(String fromDate, String toDate) {
        Datetime in5Seconds = Datetime.now().addSeconds(5);
        System.schedule(
            'RivhitIntegration',
            String.valueOf(in5Seconds.second()) + ' ' + String.valueOf(in5Seconds.minute()) + ' ' + String.valueOf(in5Seconds.hour()) + ' * * ?',
            new RivhitIntegration(fromDate, toDate)
        );
    }

    private String fromDate;
    private String toDate;
    public RivhitIntegration() {}
    public RivhitIntegration(String fromDate, String toDate) {
        this.fromDate = fromDate;
        this.toDate = toDate;
    }
    global void execute(SchedulableContext sc) {
        System.enqueueJob(new AccountBalance(
            new List<Id>(new Map<Id, Account>([SELECT Id FROM Account WHERE Finance_Acct_num__c!=null]).keySet()),
            new List<String>(), new List<String>(),
            fromDate, toDate
        ));
    }

    private static String bodyMocks(String method) {
        if (method == 'AccountBalance')
            return '{"error_code":2147483647,"client_message":"String content","debug_message":"String content","data":{"balance":12678967.543233}}';
        else if (method == 'Invoices')
            return '{"error_code":2147483647,"client_message":"String content","debug_message":"String content","data":{"document_list":[{"document_type":2147483647,"document_number":2147483647,"document_date":"31/12/1999","document_time":"String content","amount":12678967.543233,"amount_exempt":12678967.543233,"customer_id":2147483647,"agent_id":2147483647,"is_cancelled":true}]}}';
        else if (method == 'InvoicesStatuses')
            return '{"error_code":2147483647,"client_message":"String content","debug_message":"String content","data":{"open_documents":[{"balance":12678967.543233,"currency_id":2147483647,"customer_id":2147483647,"customer_name":"String content","document_number":2147483647,"document_type":2147483647,"due_date":"String content","issue_date":"String content","paid_amount":12678967.543233,"total_amount":12678967.543233,"total_amount_mtc":12678967.543233}]}}';
        else if (method == 'InvoiceDetails')
            return '{"error_code":2147483647,"client_message":"String content","debug_message":"String content","data":{"agent_id":2147483647,"comments":"String content","company_address":"String content","company_fax":"String content","company_id":2147483647,"company_name":"String content","company_phone":"String content","customer_address":"String content","customer_city":"String content","customer_id":2147483647,"customer_id_number":2147483647,"customer_name":"String content","customer_phone":"String content","customer_zipcode":2147483647,"discount_amount":12678967.543233,"discount_percent":12678967.543233,"document_date":"String content","document_due_date":"String content","document_number":"String content","document_total":12678967.543233,"document_type":"String content","documnet_time":"String content","items":[{"bruto_price_nis":12678967.543233,"catalog_number":"String content","description":"String content","discount":12678967.543233,"item_id":2147483647,"line":2147483647,"price_nis":12678967.543233,"quantity":12678967.543233,"storage_id":2147483647,"total_line":12678967.543233}],"order":"String content","payments":[{"account_number":"String content","amount":12678967.543233,"bank":2147483647,"branch":2147483647,"check_number":2147483647,"details":"String content","due_date":"String content","line_number":2147483647,"payment_type":"String content"}],"receipt_total":12678967.543233,"reference":2147483647,"total_vat":12678967.543233,"total_without_vat":12678967.543233,"vat_percent":"String content"}}';
        else if (method == 'InvoiceLineDetails')
            return '{"error_code":2147483647,"client_message":"String content","debug_message":"String content","data":{"item_extended_description":"String content","item_name":"String content","item_part_num":"String content","barcode":"String content","picture_link":"String content","item_group_id":2147483647,"storage_id":2147483647,"cost_nis":12678967.543233,"sale_nis":12678967.543233,"cost_mtc":12678967.543233,"sale_mtc":12678967.543233}}';
        return null;
    }

    // Customer.Balance
    private class AccountBalance implements Queueable {
        private List<Id> ids;
        private List<String> success;
        private List<String> errors;
        private String fromDate;
        private String toDate;
        public AccountBalance(List<Id> ids, List<String> success, List<String> errors, String fromDate, String toDate) {
            this.ids = ids;
            this.success = success;
            this.errors = errors;
            this.fromDate = fromDate;
            this.toDate = toDate;
        }
        public void execute(QueueableContext context) { AccountBalance(ids, success, errors, fromDate, toDate); }
    }
    @Future(callout=true) private static void AccountBalance(List<Id> ids, List<String> success, List<String> errors, String fromDate, String toDate) { AccountBalanceTestable(ids, success, errors, fromDate, toDate); }
    public static void AccountBalanceTestable(List<Id> ids, List<String> success, List<String> errors, String fromDate, String toDate) {
        try {
            Account account = [SELECT Id, Finance_Acct_num__c FROM Account WHERE Id=:ids.remove(0)];
            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint('https://api.rivhit.co.il/online/RivhitOnlineAPI.svc/Customer.Balance');
                req.setMethod('POST');
                req.setHeader('Accept', 'application/json; charset=utf-8');
                req.setHeader('Content-Type', 'application/json');
                req.setBody(JSON.serialize(new Map<String, Object>{
                    'api_token' => api_token,
                    'customer_id' => Integer.valueOf(account.Finance_Acct_num__c)
                }));
                String body = Test.isRunningTest() ? bodyMocks('AccountBalance') : new Http().send(req).getBody();
                System.debug('body:');
                System.debug(body);

                Decimal balance;
                try {
                    balance = (Decimal)((Map<String, Object>)((Map<String, Object>)JSON.deserializeUntyped(body)).get('data')).get('balance');
                    System.debug('balance:');
                    System.debug(balance);
                } catch(Exception e) {
                    throw new RivhitException(body);
                }

                account.Account_Balance__c = balance;
                update account;
                System.debug('account:');
                System.debug(account);
                success.add(account.Id);
            } catch(Exception e) {
                errors.add(account.Id + ' - ' + (e.getTypeName().contains('RivhitException') ? JSON.deserializeUntyped(e.getMessage()) : e.getTypeName() + ': ' + e.getMessage()));
            }
            System.enqueueJob(new AccountBalance(ids, success, errors, fromDate, toDate));
        } catch(ListException e) {
            insert new Integration_Log__c(
                Type__c='Rivhit',
                Run_date__c=Datetime.now(),
                Result__c='AccountBalance: ' + (!errors.isEmpty() ? 'error' : 'success'),
                Details__c='success: ' + String.join(success, ', ') + '\n\nerrors:\n'  + String.join(errors, '\n')
            );

            System.enqueueJob(new Invoices(fromDate, toDate));
        }
    }

    // Document.List
    private class Invoices implements Queueable {
        private String fromDate;
        private String toDate;
        public Invoices(String fromDate, String toDate) {
            this.fromDate = fromDate;
            this.toDate = toDate;
        }
        public void execute(QueueableContext context) { Invoices(fromDate, toDate); }
    }
    @Future(callout=true) private static void Invoices(String fromDate, String toDate) { InvoicesTestable(fromDate, toDate); }
    public static void InvoicesTestable(String fromDate, String toDate) {
        List<String> success = new List<String>();
        List<String> errors = new List<String>();
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://api.rivhit.co.il/online/RivhitOnlineAPI.svc/Document.List');
            req.setMethod('POST');
            req.setHeader('Accept', 'application/json; charset=utf-8');
            req.setHeader('Content-Type', 'application/json');
            Map<String, Object> data = new Map<String, Object>{
                'api_token' => api_token,
                'from_document_type' => 1,
                'to_document_type' => 3
            };
            if (fromDate != null) data.put('from_date', fromDate);
            if (toDate != null) data.put('to_date', toDate);
            req.setBody(JSON.serialize(data));
            String body = Test.isRunningTest() ? bodyMocks('Invoices') : new Http().send(req).getBody();
            System.debug('body:');
            System.debug(body);

            List<Object> documents;
            try {
                documents = (List<Object>)((Map<String, Object>)((Map<String, Object>)JSON.deserializeUntyped(body)).get('data')).get('document_list');
                System.debug('documents:');
                System.debug(documents);
            } catch(Exception e) {
                throw new RivhitException(body);
            }

            List<Account> accounts = [SELECT Id, Finance_Acct_num__c FROM Account WHERE Finance_Acct_num__c!=null];
            Map<String, String> accountIdByFinAccNum = new Map<String, String>();
            for (Account account : accounts)
                accountIdByFinAccNum.put(account.Finance_Acct_num__c, account.Id);
            System.debug('accountIdByFinAccNum:');
            System.debug(accountIdByFinAccNum);

            Set<String> missing = new Set<String>();
            List<Invoice__c> invoices = new List<Invoice__c>();
            for (Object d : documents) {
                Map<String, Object> document = (Map<String, Object>)d;
                String finAccNum = String.valueOf(document.get('customer_id'));
                String accountId = accountIdByFinAccNum.get(finAccNum);
                if (accountId != null) {
                    List<String> invoiceDate = ((String)document.get('document_date')).split('/');
                    invoices.add(new Invoice__c(
                        Account__c=accountId,
                        Invoice__c=String.valueOf(document.get('document_number')),
                        Invoice_Unique__c=String.valueOf(document.get('document_type')) + '-' + String.valueOf(document.get('document_number')),
                        Invoice_Type__c=(Integer)document.get('document_type'),
                        Invoice_Date__c=Date.newInstance(Integer.valueOf(invoiceDate[2]), Integer.valueOf(invoiceDate[1]), Integer.valueOf(invoiceDate[0])),
                        Is_Cancelled__c=(Boolean)document.get('is_cancelled')
                    ));
                } else
                    missing.add(finAccNum);
            }
            if (!missing.isEmpty())
                errors.add('missing Accounts with these Finance_Acct_num: ' + String.join(new List<String>(missing), ', '));

            upsert invoices Invoice__c.Invoice_Unique__c;
            System.debug('invoices:');
            System.debug(invoices);
            for (Invoice__c invoice : invoices)
                success.add(invoice.Id);
        } catch(Exception e) {
            errors.add('' + (e.getTypeName().contains('RivhitException') ? JSON.deserializeUntyped(e.getMessage()) : e.getTypeName() + ': ' + e.getMessage()));
        }

        insert new Integration_Log__c(
            Type__c='Rivhit',
            Run_date__c=Datetime.now(),
            Result__c='Invoices: ' + (!errors.isEmpty() ? 'error' : 'success'),
            Details__c='success: ' + String.join(success, ', ') + '\n\nerrors:\n'  + String.join(errors, '\n')
        );

        System.enqueueJob(new InvoicesStatuses(
            new List<Id>(new Map<Id, Account>([SELECT Id FROM Account WHERE Finance_Acct_num__c!=null]).keySet()),
            new List<String>(), new List<String>()
        ));
    }

    // Customer.OpenDocuments
    private class InvoicesStatuses implements Queueable {
        private List<Id> ids;
        private List<String> success;
        private List<String> errors;
        public InvoicesStatuses(List<Id> ids, List<String> success, List<String> errors) {
            this.ids = ids;
            this.success = success;
            this.errors = errors;
        }
        public void execute(QueueableContext context) { InvoicesStatuses(ids, success, errors); }
    }
    @Future(callout=true) private static void InvoicesStatuses(List<Id> ids, List<String> success, List<String> errors) { InvoicesStatusesTestable(ids, success, errors); }
    public static void InvoicesStatusesTestable(List<Id> ids, List<String> success, List<String> errors) {
        try {
            Account account = [SELECT Id, Finance_Acct_num__c, (SELECT Id, Invoice__c, Total_Amount__c FROM Invoices__r) FROM Account WHERE Id=:ids.remove(0)];
            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint('https://api.rivhit.co.il/online/RivhitOnlineAPI.svc/Customer.OpenDocuments');
                req.setMethod('POST');
                req.setHeader('Accept', 'application/json; charset=utf-8');
                req.setHeader('Content-Type', 'application/json');
                req.setBody(JSON.serialize(new Map<String, Object>{
                    'api_token' => api_token,
                    'customer_id' => Integer.valueOf(account.Finance_Acct_num__c),
                    'by_produce_date' => true
                }));
                String body = Test.isRunningTest() ? bodyMocks('InvoicesStatuses') : new Http().send(req).getBody();
                System.debug('body:');
                System.debug(body);

                List<Object> openDocuments;
                try {
                    openDocuments = (List<Object>)((Map<String, Object>)((Map<String, Object>)JSON.deserializeUntyped(body)).get('data')).get('open_documents');
                    System.debug('openDocuments:');
                    System.debug(openDocuments);
                } catch(Exception e) {
                    throw new RivhitException(body);
                }

                Map<String, Invoice__c> invoiceByNumber = new Map<String, Invoice__c>();
                for (Invoice__c invoice : account.Invoices__r) {
                    invoice.Balance__c = 0;
                    invoice.Paid_Amount__c = invoice.Total_Amount__c;
                    invoice.Closed__c = true;
                    invoiceByNumber.put(invoice.Invoice__c, invoice);
                }

                Set<String> missing = new Set<String>();
                for (Object d : openDocuments) {
                    Map<String, Object> document = (Map<String, Object>)d;
                    Integer invoiceType = (Integer)document.get('document_type');
                    if (invoiceType == 1 || invoiceType == 2 || invoiceType == 3) {
                        String invoiceNumber = String.valueOf(document.get('document_number'));
                        Invoice__c invoice = invoiceByNumber.get(invoiceNumber);
                        if (invoice != null) {
                            invoice.Balance__c = (Decimal)document.get('balance');
                            invoice.Paid_Amount__c = (Decimal)document.get('paid_amount');
                            invoice.Closed__c = false;
                        } else {
                            Integer invoiceYear = Integer.valueOf(((String)document.get('issue_date')).split('/')[2]);
                            if (invoiceYear > 2015)
                                missing.add(invoiceNumber);
                        }
                    }
                }
                if (!missing.isEmpty())
                    errors.add(account.Id + ' - missing Invoices with these Invoice__c: ' + String.join(new List<String>(missing), ', '));

                System.debug('invoices:');
                System.debug(account.Invoices__r);
                update account.Invoices__r;

                System.debug('account:');
                System.debug(account);
                success.add(account.Id);
            } catch(Exception e) {
                errors.add(account.Id + ' - ' + (e.getTypeName().contains('RivhitException') ? JSON.deserializeUntyped(e.getMessage()) : e.getTypeName() + ': ' + e.getMessage()));
            }
            System.enqueueJob(new InvoicesStatuses(ids, success, errors));
        } catch(ListException e) {
            insert new Integration_Log__c(
                Type__c='Rivhit',
                Run_date__c=Datetime.now(),
                Result__c='InvoicesStatuses: ' + (!errors.isEmpty() ? 'error' : 'success'),
                Details__c='success: ' + String.join(success, ', ') + '\n\nerrors:\n'  + String.join(errors, '\n')
            );

            System.enqueueJob(new InvoiceDetails(
                new List<Id>(new Map<Id, Invoice__c>([SELECT Id FROM Invoice__c WHERE Total_Amount__c=null]).keySet()),
                new List<String>(), new List<String>()
            ));
        }
    }


    // Document.Details
    private class InvoiceDetails implements Queueable {
        private List<Id> ids;
        private List<String> success;
        private List<String> errors;
        public InvoiceDetails(List<Id> ids, List<String> success, List<String> errors) {
            this.ids = ids;
            this.success = success;
            this.errors = errors;
        }
        public void execute(QueueableContext context) { InvoiceDetails(ids, success, errors); }
    }
    @Future(callout=true) private static void InvoiceDetails(List<Id> ids, List<String> success, List<String> errors) { InvoiceDetailsTestable(ids, success, errors); }
    public static void InvoiceDetailsTestable(List<Id> ids, List<String> success, List<String> errors) {
        try {
            Invoice__c invoice = [SELECT Id, Invoice__c, Invoice_Type__c FROM Invoice__c WHERE Id=:ids.remove(0)];
            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint('https://api.rivhit.co.il/online/RivhitOnlineAPI.svc/Document.Details');
                req.setMethod('POST');
                req.setHeader('Accept', 'application/json; charset=utf-8');
                req.setHeader('Content-Type', 'application/json');
                req.setBody(JSON.serialize(new Map<String, Object>{
                    'api_token' => api_token,
                    'document_number' => Integer.valueOf(invoice.Invoice__c),
                    'document_type' => invoice.Invoice_Type__c
                }));
                String body = Test.isRunningTest() ? bodyMocks('InvoiceDetails') : new Http().send(req).getBody();
                System.debug('body:');
                System.debug(body);

                Map<String, Object> document;
                List<Object> items;
                try {
                    document = (Map<String, Object>)((Map<String, Object>)JSON.deserializeUntyped(body)).get('data');
                    items = (List<Object>)document.get('items');
                    System.debug('items:');
                    System.debug(items);
                } catch(Exception e) {
                    throw new RivhitException(body);
                }

                List<Invoice_Line__c> lines = new List<Invoice_Line__c>();
                for (Object i : items) {
                    Map<String, Object> item = (Map<String, Object>)i;
                    lines.add(new Invoice_Line__c(
                        Invoice__c=invoice.Id,
                        bruto_price_nis__c=(Decimal)item.get('bruto_price_nis'),
                        catalog_number__c=(String)item.get('catalog_number'),
                        description__c=(String)item.get('description'),
                        discount__c=(Decimal)item.get('discount'),
                        item_id__c=String.valueOf(item.get('item_id')),
                        line__c=String.valueOf(item.get('line')),
                        price_nis__c=(Decimal)item.get('price_nis'),
                        quantity__c=(Decimal)item.get('quantity'),
                        storage_id__c=String.valueOf(item.get('storage_id')),
                        total_line__c=(Decimal)item.get('total_line')
                    ));
                }
                insert lines;
                System.debug('lines:');
                System.debug(lines);

                invoice.Amount__c = (Decimal)document.get('total_without_vat');
                invoice.VAT__c = (Decimal)document.get('total_vat');
                invoice.Total_Amount__c = invoice.Amount__c + invoice.VAT__c;
                update invoice;
                System.debug('invoice:');
                System.debug(invoice);
                success.add(invoice.Id);
            } catch(Exception e) {
                errors.add(invoice.Id + ' - ' + (e.getTypeName().contains('RivhitException') ? JSON.deserializeUntyped(e.getMessage()) : e.getTypeName() + ': ' + e.getMessage()));
            }
            System.enqueueJob(new InvoiceDetails(ids, success, errors));
        } catch(ListException e) {
            insert new Integration_Log__c(
                Type__c='Rivhit',
                Run_date__c=Datetime.now(),
                Result__c='InvoiceDetails: ' + (!errors.isEmpty() ? 'error' : 'success'),
                Details__c='success: ' + String.join(success, ', ') + '\n\nerrors:\n'  + String.join(errors, '\n')
            );

            System.enqueueJob(new InvoiceLineDetails(
                new List<Id>(new Map<Id, Invoice_Line__c>([SELECT Id FROM Invoice_Line__c WHERE item_group_id__c=null]).keySet()),
                new List<String>(), new List<String>()
            ));
        }
    }

    // Item.Details
    private class InvoiceLineDetails implements Queueable {
        private List<Id> ids;
        private List<String> success;
        private List<String> errors;
        public InvoiceLineDetails(List<Id> ids, List<String> success, List<String> errors) {
            this.ids = ids;
            this.success = success;
            this.errors = errors;
        }
        public void execute(QueueableContext context) { InvoiceLineDetails(ids, success, errors); }
    }
    @Future(callout=true) private static void InvoiceLineDetails(List<Id> ids, List<String> success, List<String> errors) { InvoiceLineDetailsTestable(ids, success, errors); }
    public static void InvoiceLineDetailsTestable(List<Id> ids, List<String> success, List<String> errors) {
        try {
            String item_id = [SELECT Id, item_id__c FROM Invoice_Line__c WHERE Id=:ids.remove(0)].item_id__c;
            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint('https://api.rivhit.co.il/online/RivhitOnlineAPI.svc/Item.Details');
                req.setMethod('POST');
                req.setHeader('Accept', 'application/json; charset=utf-8');
                req.setHeader('Content-Type', 'application/json');
                req.setBody(JSON.serialize(new Map<String, Object>{
                    'api_token' => api_token,
                    'item_id' => Integer.valueOf(item_id)
                }));
                String body = Test.isRunningTest() ? bodyMocks('InvoiceLineDetails') : new Http().send(req).getBody();
                System.debug('body:');
                System.debug(body);

                Integer item_group_id;
                try {
                    item_group_id = (Integer)((Map<String, Object>)((Map<String, Object>)JSON.deserializeUntyped(body)).get('data')).get('item_group_id');
                    System.debug('item_group_id:');
                    System.debug(item_group_id);
                } catch(Exception e) {
                    throw new RivhitException(body);
                }

                List<Invoice_Line__c> lines = [SELECT Id FROM Invoice_Line__c WHERE item_id__c=:item_id AND item_group_id__c=null LIMIT 200];
                for (Invoice_Line__c line : lines) {
                    line.item_group_id__c = item_group_id;
                    Integer i = 0;
                    for (String id : ids)
                        if (line.Id == id) {
                            ids.remove(i);
                            break;
                        }
                        i++;
                }
                update lines;
                System.debug('lines:');
                System.debug(lines);
                for (Invoice_Line__c line : lines)
                    success.add(line.Id);
            } catch(Exception e) {
                errors.add('' + (e.getTypeName().contains('RivhitException') ? JSON.deserializeUntyped(e.getMessage()) : e.getTypeName() + ': ' + e.getMessage()));
            }
            System.enqueueJob(new InvoiceLineDetails(ids, success, errors));
        } catch(ListException e) {
            insert new Integration_Log__c(
                Type__c='Rivhit',
                Run_date__c=Datetime.now(),
                Result__c='InvoiceLineDetails: ' + (!errors.isEmpty() ? 'error' : 'success'),
                Details__c='success: ' + String.join(success, ', ') + '\n\nerrors:\n'  + String.join(errors, '\n')
            );
        }
    }
}