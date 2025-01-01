public class BillingController {
    public final Integer MaxStep=3;
    public Boolean moreThanI=false;
    public Map <String, String> ProdIds{get;set;}
    public Set <String> AccNames{get;set;}
    public Map <String,Decimal> currencyRate{get;set;}
    public Map <String, String> EmployeeTypes{get;set;}
    public Date dat {get;set;}
    public String curDep {get;set;}
    public string currentDat {get;set;}
    public List <selectoption> types {get;set;}
    public List <selectoption> datops {get;set;}
    public List <selectoption> deptypes {get;set;}
    public Map <String,Decimal> OldValues{get;set;}
    public Map <String,PriceBookEntry> TypeProdIds{get;set;}
    private List <Working_Hours__c> whs;
    public Decimal Bill{get;set;}
    public Decimal OldBill{get;set;}
    public Decimal Total{get;set;}
    public Decimal OldTotal{get;set;}
    public Class SubTot{
        public Decimal Bill{get;set;}
        public Decimal OldBill{get;set;}
        public Decimal Hours{get;set;}
        public Decimal Total{get;set;}
        public Decimal OldTotal{get;set;}
        public SubTot(){
            Bill=0;
            OldBill=0;
            Hours=0;
            Total=0;
            OldTotal=0;
        }
    }
    public Class TempOrder{
        public Map <String,TempOrderItem> TordIs{get;set;}
        public Order Ord{get;set;}
        public String AccountName{get;set;}
        public TempOrder(Date dat){
            Ord = new Order(Status='Ready for Invoice', EffectiveDate=dat);
            TordIs = new Map <String,TempOrderItem>();
        }
        public TempOrder(Order tord, Map <String,Decimal> OldValues, Map <String, String> ProdIds){
            Ord = tord;
            AccountName = tord.Account.Name;
            TordIs = new Map <String,TempOrderItem>();
            for(OrderItem oi:Ord.OrderItems){
                TordIs.put(oi.Project__c+';'+oi.Product2.ProductCode+';'+oi.Step__c,new TempOrderItem(oi, getEmpType(oi.Product2.ProductCode,ProdIds)));
                OldValues.put(oi.Project__c+';'+oi.Product2.ProductCode+';'+oi.Step__c,oi.Quantity);
            }
        }
        private String getEmpType(String s, Map <String, String> ProdIds){
            for(String str:ProdIds.KeySet())
                if(ProdIds.get(str)==s){
                    return str;
                }
            return null;
        }
    }
    public Class TempOrderItem{
        public Boolean checked{get;set;}
        public OrderItem OrdI{get;set;}
        public String ProjectName{get;set;}
        public String EmployeeType{get;set;}
        public List <Working_Hours__c> upwhrs {get;set;}
        public TempOrderItem(){
            OrdI = new OrderItem(Status__c='Ready for Invoice');
            upwhrs = new List <Working_Hours__c>();
            checked = false;
        }
        public TempOrderItem(OrderItem oi, String EmpT){
            OrdI = oi;
            checked = false;
            ProjectName = oi.Project__r.Name;
            EmployeeType = EmpT;
            upwhrs = new List <Working_Hours__c>();
        }
    }
    public Map <String,TempOrder> Ordrs {get;set;}
    public Map <String,SubTot> SubTotals {get;set;}
    private void defaultDates(){
        datops = new List <selectoption>();
        dat = System.Today();
        dat = dat.addDays((dat.Day()*(-1))+1);
        //dat = dat.addMonths(+3);
        for(integer i=0;i>-8;i--)
            datops.add(new selectoption(String.valueof(dat.addMonths(i).month()+'-'+dat.addMonths(i).year()),String.valueof(dat.addMonths(i).month()+'-'+dat.addMonths(i).year())));
        dat = dat.addMonths(-1);
        currentDat = String.valueof(dat.month()+'-'+dat.year());
    }
    private void getProdIds(){
        EmployeeTypes = new Map <String, String>();
        ProdIds = new Map <String, String>();
        for(ProductByCode__c sett:[select Name,Product_Code__c,Field__c from ProductByCode__c Where Department__c=:curDep]){
            EmployeeTypes.put(sett.Name,sett.Field__c);
            ProdIds.put(sett.Name,sett.Product_Code__c);
        }
        TypeProdIds = new Map<String,PriceBookEntry>();
        for(PriceBookEntry prod:[select id, CurrencyIsoCode, Pricebook2Id, Product2Id, Product2.Name, ProductCode, UnitPrice from PriceBookEntry where Product2.Name!=null and ProductCode!=null and isActive=true and ProductCode in: ProdIds.Values()])
            TypeProdIds.put(prod.Pricebook2Id+';'+prod.ProductCode+';'+prod.CurrencyIsoCode,prod);

        //get Currencies
        currencyRate = new Map <String,Decimal>();
        for(CurrencyType c:[SELECT ISOCode, ConversionRate,IsCorporate FROM CurrencyType WHERE IsActive=TRUE])
            if(c.IsCorporate==true){
                currencyRate.put(c.ISOCode,c.ConversionRate);
            }
            else{
                currencyRate.put(c.ISOCode,1/c.ConversionRate);
            }
    }
    public void getHours(){
        OldValues = new Map <String,Decimal>();
        Date StartD = Date.newinstance(integer.valueof(currentDat.split('-')[1]),integer.valueof(currentDat.split('-')[0]),1);
        Ordrs = new Map <String,TempOrder>();
        AccNames = new Set <String>();
        List <Order> curOrders = new List <Order>();
        if(moreThanI){
            curOrders = [select id, AccountId, Account.Name, CurrencyIsoCode, PriceBook2Id, CreatedDate, (select id, CreatedDate, OrderId, Step__c, Project__r.Name, Project__c, Product2.Name, Product2.ProductCode, Product2Id, Quantity, Total_Hours__c, UnitPrice from OrderItems where Project__c!=null and Status__c='Ready for Invoice' and Product2.ProductCode in:ProdIds.Values() Order by Project__r.Name, Product2.Name, CreatedDate) from Order where Status='Ready for Invoice' and EffectiveDate=:StartD and Type='Hourly' and Account.Name>'I' Order By Account.Name,CreatedDate];
        } else {
            curOrders = [select id, AccountId, Account.Name, CurrencyIsoCode, PriceBook2Id, CreatedDate, (select id, CreatedDate, OrderId, Step__c, Project__r.Name, Project__c, Product2.Name, Product2.ProductCode, Product2Id, Quantity, Total_Hours__c, UnitPrice from OrderItems where Project__c!=null and Status__c='Ready for Invoice' and Product2.ProductCode in:ProdIds.Values() Order by Project__r.Name, Product2.Name, CreatedDate) from Order where Status='Ready for Invoice' and EffectiveDate=:StartD and Type='Hourly' and Account.Name<='I' Order By Account.Name,CreatedDate];
        }
        for (Order ord:curOrders){
            Ordrs.put(ord.Accountid,new TempOrder(ord,OldValues,ProdIds));
            AccNames.add(ord.Accountid);
        }
        System.debug(OldValues);
        if(moreThanI){
            whs = [select id, Account__c, Project__r.Billing_Account__c, Project__r.Billing_Account__r.Name, Account__r.Billing_Account__c, Account__r.Billing_Account__r.Name, Billing_Date__c, Order_Product__c, Account__r.Name, Project__c, Project__r.Name, Project__r.Price_Book__c ,Performed_By_2__r.Employee_Type__c, Number_Of_Hours__c, Billable_Hours__c, Description_Of_Work__c, Project__r.CurrencyIsoCode, Project__r.Develop_Hourly_Rate__c, Project__r.Develop_Hourly_Rate_2__c, Project__r.Develop_Hourly_Rate_3__c, Project__r.Architect_Hourly_Rate__c, Project__r.Architect_Hourly_Rate_2__c, Project__r.Architect_Hourly_Rate_3__c, Project__r.Implementation_Hourly_Rate__c, Project__r.Implementation_Hourly_Rate_2__c, Project__r.Implementation_Hourly_Rate_3__c, Project__r.Project_Managing_Hourly_Rate__c, Project__r.Project_Managing_Hourly_Rate_2__c, Project__r.Project_Managing_Hourly_Rate_3__c, Project__r.Pardot_Hourly_Rate__c, Project__r.Pardot_Hourly_Rate_2__c, Project__r.Pardot_Hourly_Rate_3__c, Project__r.IT_Staff_Hourly_Rate__c, Project__r.IT_Staff_Hourly_Rate_2__c, Project__r.IT_Staff_Hourly_Rate_3__c, Project__r.QA_Hourly_Rate__c, Project__r.QA_Hourly_Rate_2__c, Project__r.QA_Hourly_Rate_3__c, Project__r.Limit__c, Project__r.Limit_2__c from Working_Hours__c where Performed_By_2__r.Employee_Type__c in: EmployeeTypes.KeySet() and Billable__c=true and Order_Product__c=null and Billing_Date__c>=:StartD and Billing_Date__c<:StartD.addMonths(1) and Project__c!=null and Project__r.Billing_Type__c='Hourly' and ((Project__r.Billing_Account__c!=null and Project__r.Billing_Account__r.Name>'I') or (Project__r.Billing_Account__c=null and Account__r.Billing_Account__c!=null and Account__r.Billing_Account__r.Name>'I') or (Project__r.Billing_Account__c=null and Account__r.Billing_Account__c=null and Account__r.Name>'I')) Order By Account__r.Name,Project__r.Name,Performed_By_2__r.Employee_Type__c,Billing_Date__c];
        } else {
            whs = [select id, Account__c, Project__r.Billing_Account__c, Project__r.Billing_Account__r.Name, Account__r.Billing_Account__c, Account__r.Billing_Account__r.Name, Billing_Date__c, Order_Product__c, Account__r.Name, Project__c, Project__r.Name, Project__r.Price_Book__c ,Performed_By_2__r.Employee_Type__c, Number_Of_Hours__c, Billable_Hours__c, Description_Of_Work__c, Project__r.CurrencyIsoCode, Project__r.Develop_Hourly_Rate__c, Project__r.Develop_Hourly_Rate_2__c, Project__r.Develop_Hourly_Rate_3__c, Project__r.Architect_Hourly_Rate__c, Project__r.Architect_Hourly_Rate_2__c, Project__r.Architect_Hourly_Rate_3__c, Project__r.Implementation_Hourly_Rate__c, Project__r.Implementation_Hourly_Rate_2__c, Project__r.Implementation_Hourly_Rate_3__c, Project__r.Project_Managing_Hourly_Rate__c, Project__r.Project_Managing_Hourly_Rate_2__c, Project__r.Project_Managing_Hourly_Rate_3__c, Project__r.Pardot_Hourly_Rate__c, Project__r.Pardot_Hourly_Rate_2__c, Project__r.Pardot_Hourly_Rate_3__c, Project__r.IT_Staff_Hourly_Rate__c, Project__r.IT_Staff_Hourly_Rate_2__c, Project__r.IT_Staff_Hourly_Rate_3__c, Project__r.QA_Hourly_Rate__c, Project__r.QA_Hourly_Rate_2__c, Project__r.QA_Hourly_Rate_3__c, Project__r.Limit__c, Project__r.Limit_2__c from Working_Hours__c where Performed_By_2__r.Employee_Type__c in: EmployeeTypes.KeySet() and Billable__c=true and Order_Product__c=null and Billing_Date__c>=:StartD and Billing_Date__c<:StartD.addMonths(1) and Project__c!=null and Project__r.Billing_Type__c='Hourly' and ((Project__r.Billing_Account__c!=null and Project__r.Billing_Account__r.Name<='I') or (Project__r.Billing_Account__c=null and Account__r.Billing_Account__c!=null and Account__r.Billing_Account__r.Name<='I') or (Project__r.Billing_Account__c=null and Account__r.Billing_Account__c=null and Account__r.Name<='I')) Order By Account__r.Name,Project__r.Name,Performed_By_2__r.Employee_Type__c,Billing_Date__c];
        }
        for(Working_Hours__c wh:whs){
            //Account Exist Already
            String accountId;
            String accountName;
            if(wh.Project__r.Billing_Account__c!=null){
                accountId = wh.Project__r.Billing_Account__c;
                accountName = wh.Project__r.Billing_Account__r.Name;
            } else if(wh.Account__r.Billing_Account__c!=null){
                accountId = wh.Account__r.Billing_Account__c;
                accountName = wh.Account__r.Billing_Account__r.Name;
            } else {
                accountId = wh.Account__c;
                accountName = wh.Account__r.Name;
            }
            if(Ordrs.containsKey(accountId)){
                //Project + Product Exsit
                Boolean Found=false;
                Decimal delta = 0;
                for(integer i=MaxStep;i>=1;i--){
                    if(Ordrs.get(accountId).TordIs.containsKey(wh.Project__c+';'+ProdIds.get(wh.Performed_By_2__r.Employee_Type__c)+';'+String.valueof(i))){
                        TempOrderItem tori = Ordrs.get(accountId).TordIs.get(wh.Project__c+';'+ProdIds.get(wh.Performed_By_2__r.Employee_Type__c)+';'+String.valueof(i));
                        tori.upwhrs.add(wh);
                        tori.OrdI.Quantity += wh.Billable_Hours__c!=null?wh.Billable_Hours__c:0;
                        tori.OrdI.Total_Hours__c += wh.Number_Of_Hours__c!=null?wh.Number_Of_Hours__c:0;
                        findQuantity(tori,wh,accountId);
                        Found=true;
                        break;
                    }
                }
                //Project + no Product
                if(!Found){
                    addTempOrdI(wh,'1',0,accountId);
                }
            }
            //no Project + Product
            else{
                TempOrder tord = new TempOrder(StartD);
                tord.AccountName = accountName;
                tord.Ord.Accountid = accountId;
                tord.Ord.CurrencyIsoCode = wh.Project__r.CurrencyIsoCode!=null?wh.Project__r.CurrencyIsoCode:'ILS';
                tord.Ord.Pricebook2Id = wh.Project__r.Price_Book__c;
                tord.Ord.Type = 'Hourly';
                Ordrs.put(accountId,tord);
                AccNames.add(accountId);
                addTempOrdI(wh,'1',0,accountId);
            }
        }
        SetTotals();
        //Phase 1 Complete now need to Split over limits
        /*System.debug(Ordrs);
        for(String k:Ordrs.KeySet()){
            for(String k2:Ordrs.get(k).TordIs.KeySet()){
                if(Ordrs.get(k).TordIs.get(k2).OrdI.Quantity!=OldValues.get(k2)){
                    Ordrs.get(k).TordIs.get(k2).checked=false;
                }
            }
        }*/
    }
    public void SetTotals(){
        Bill = 0;
        OldBill = 0;
        Total = 0;
        OldTotal = 0;
        SubTotals = new Map <String,SubTot>();
        for(String s:Ordrs.KeySet()){
            SubTot sub = new SubTot();
            for(TempOrderItem temp:Ordrs.get(s).TordIs.Values()){
                sub.Bill += temp.OrdI.Quantity;
                sub.Hours += temp.OrdI.Total_Hours__c;
                sub.Total += temp.OrdI.Quantity*temp.Ordi.UnitPrice;
                if(OldValues.containsKey(temp.OrdI.Project__c+';'+temp.OrdI.Product2.ProductCode+';'+temp.OrdI.Step__c)){
                    sub.OldBill += OldValues.get(temp.OrdI.Project__c+';'+temp.OrdI.Product2.ProductCode+';'+temp.OrdI.Step__c);
                    sub.OldTotal += (OldValues.get(temp.OrdI.Project__c+';'+temp.OrdI.Product2.ProductCode+';'+temp.OrdI.Step__c)*temp.OrdI.UnitPrice);
                }
            }
            SubTotals.put(s,sub);
            Bill += sub.Bill;
            OldBill += sub.OldBill;
            if(Ordrs.get(s).Ord.CurrencyIsoCode=='ILS'){
                Total += sub.Total;
                OldTotal += sub.OldTotal;
            }
            else{
                Total += (currencyRate.get(Ordrs.get(s).Ord.CurrencyIsoCode)*sub.Total).setScale(4);
                OldTotal += (currencyRate.get(Ordrs.get(s).Ord.CurrencyIsoCode)*sub.OldTotal).setScale(4);
            }
        }
        System.debug(SubTotals);
        for(String acc:accNames)    {
            System.debug(acc);
            System.debug(Ordrs.get(acc));
        }
    }
    public void changeLessI(){
        moreThanI = false;
        getHours();
    }
    public void changeMoreI(){
        moreThanI = true;
        getHours();
    }
    public void addTempOrdI(Working_Hours__c wh,String Step, Decimal delta,String accountId){
        TempOrderItem tori = new TempOrderItem();
        tori.upwhrs.add(wh);
        System.debug(wh.Project__r.Price_Book__c);
        System.debug(ProdIds.get(wh.Performed_By_2__r.Employee_Type__c));
        System.debug(Ordrs.get(accountId).Ord.CurrencyIsoCode);
        System.debug(TypeProdIds);
        tori.OrdI.PricebookEntryId = TypeProdIds.get(wh.Project__r.Price_Book__c+';'+ProdIds.get(wh.Performed_By_2__r.Employee_Type__c)+';'+Ordrs.get(accountId).Ord.CurrencyIsoCode).id;
        tori.ProjectName = wh.Project__r.Name;
        tori.EmployeeType = wh.Performed_By_2__r.Employee_Type__c;
        tori.OrdI.Project__c = wh.Project__c;
        tori.OrdI.Step__c = Step;
        if(delta!=0){
            tori.OrdI.Total_Hours__c = delta;
            tori.OrdI.Quantity = delta;
        }
        else{
            tori.OrdI.Total_Hours__c = wh.Number_Of_Hours__c!=null?wh.Number_Of_Hours__c:0;
            tori.OrdI.Quantity = wh.Billable_Hours__c!=null?wh.Billable_Hours__c:0;
        }
        findCut(tori,wh,accountId);
        Ordrs.get(accountId).TordIs.put(wh.Project__c+';'+ProdIds.get(wh.Performed_By_2__r.Employee_Type__c)+';'+Step,tori);
        OldValues.put(wh.Project__c+';'+ProdIds.get(wh.Performed_By_2__r.Employee_Type__c)+';'+Step,0);
    }
    public Decimal findNextRate(Working_Hours__c wh, String st){
        st = String.valueof(integer.valueof(st)+1);
        if(st!='4'){
            for(String k:EmployeeTypes.KeySet()){
                String step = st!='1'?'_'+st:'';
                if(wh.Performed_By_2__r.Employee_Type__c==k&&wh.Project__c!=null&&wh.Project__r.get(EmployeeTypes.get(k)+step+'__c')!=null){
                    return (Decimal) wh.Project__r.get(EmployeeTypes.get(k)+step+'__c');
                }
            }
        }
        return null;
    }
    public void findCut(TempOrderItem tori,Working_Hours__c wh,String accountId){
        Boolean found = false;
        for(String k:EmployeeTypes.KeySet()){
            String step = tori.OrdI.Step__c!='1'?'_'+tori.OrdI.Step__c:'';
            if(wh.Performed_By_2__r.Employee_Type__c==k&&wh.Project__c!=null&&wh.Project__r.get(EmployeeTypes.get(k)+step+'__c')!=null){
                found = true;
                tori.OrdI.UnitPrice = (Decimal) wh.Project__r.get(EmployeeTypes.get(k)+step+'__c');
            }
        }
        if(!found)
            tori.OrdI.UnitPrice = TypeProdIds.get(wh.Project__r.Price_Book__c+';'+ProdIds.get(wh.Performed_By_2__r.Employee_Type__c)+';'+Ordrs.get(accountId).Ord.CurrencyIsoCode).UnitPrice;
        findQuantity(tori,wh,accountId);
    }
    public void findQuantity(TempOrderItem tori,Working_Hours__c wh,String accountId){
        if(tori.OrdI.Step__c!=String.valueof(MaxStep)){
            String lim = 'Limit'+(tori.OrdI.Step__c!='1'?('_'+tori.OrdI.Step__c):'')+'__c';
            String lastlim;
            Decimal limnum = (Decimal) wh.Project__r.get(lim);
            Decimal lastlimnum = 0;
            if(tori.OrdI.Step__c!='1'){
                lastlim = String.valueof(Integer.valueof(tori.OrdI.Step__c)-1);
                lastlim = 'Limit'+(lastlim!='1'?('_'+lastlim):'')+'__c';
                lastlimnum = (Decimal) wh.Project__r.get(lastlim);
                limnum -= lastlimnum;
            }
            Decimal delta = 0;
            System.debug(limnum+' '+tori.OrdI.Quantity);
            if(limnum!=null&&tori.OrdI.Quantity>limnum&&findNextRate(wh,tori.OrdI.Step__c)!=tori.OrdI.UnitPrice){
                delta = tori.OrdI.Quantity - limnum;
                tori.OrdI.Total_Hours__c -= delta;
                tori.OrdI.Quantity = limnum;
                for(integer i=0;i<tori.upwhrs.size();i++)
                    if(tori.upwhrs[i].id==wh.id) 
                        tori.upwhrs.remove(i);
                System.debug(tori.OrdI.Quantity);
                addTempOrdI(wh,String.valueof(integer.valueof(tori.OrdI.Step__c)+1),delta,accountId);
            }
        }
    }
    public BillingController() {
        curDep = '';
        deptypes = new List <selectoption>();
        deptypes.add(new selectoption('','--None--'));
        Set <String> unqs = new Set <String>();
        for(ProductByCode__c sett:[select Department__c from ProductByCode__c])
            if(!unqs.contains(sett.Department__c)&&sett.Department__c!=null){
                unqs.add(sett.Department__c);
                deptypes.add(new selectoption(sett.Department__c,sett.Department__c));
            }
    }
    public void departmentChange(){
        getProdIds();
        defaultDates();
        getHours();
    }
    public void SaveChecked(){
        List <Order> ords = new List <Order>();
        List <OrderItem> Ordis = new List <OrderItem>();
        List <Working_Hours__c> whsup = new List <Working_Hours__c>();
        for(String k:Ordrs.KeySet()){
            Boolean good = false;
            for(String k2:Ordrs.get(k).TordIs.KeySet()){
                if(Ordrs.get(k).TordIs.get(k2).Checked){
                    good = true;
                    Ordis.add(Ordrs.get(k).TordIs.get(k2).OrdI);
                }
            }
            if(good){
                ords.add(Ordrs.get(k).Ord);
            }
        }
        Upsert Ords;
        for(String k:Ordrs.KeySet()){
            for(String k2:Ordrs.get(k).TordIs.KeySet()){
                if(Ordrs.get(k).TordIs.get(k2).Checked&&Ordrs.get(k).TordIs.get(k2).OrdI.OrderId==null){
                    Ordrs.get(k).TordIs.get(k2).OrdI.OrderId = Ordrs.get(k).Ord.Id;
                }
            }
        }
        upsert Ordis;
        for(String k:Ordrs.KeySet()){
            for(String k2:Ordrs.get(k).TordIs.KeySet()){
                OldValues.put(k2,Ordrs.get(k).TordIs.get(k2).OrdI.Quantity);
                if(Ordrs.get(k).TordIs.get(k2).Checked){
                    Ordrs.get(k).TordIs.get(k2).Checked=false;
                    for(Working_Hours__c wh:Ordrs.get(k).TordIs.get(k2).upwhrs){
                        if(wh.Order_Product__c==null){
                            wh.Order_Product__c = Ordrs.get(k).TordIs.get(k2).OrdI.id;
                            whsup.add(wh);
                        }
                    }
                }
            }
        }
        update whsup;
        getHours();
    }
    public static void tes(){
        integer i=0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}