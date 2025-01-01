@isTest(seealldata=true)
public class BillingTest {
	static TestMethod void Billing() {
		BillingController bc = new BillingController();
		bc.curDep = 'Salesforce';
		bc.departmentChange();
		bc.currentDat = '7-2021';
		bc.getHours();
		for(String k:bc.Ordrs.KeySet()){
			for(String k2:bc.Ordrs.get(k).TordIs.KeySet()){
				bc.Ordrs.get(k).TordIs.get(k2).checked=true;
				break;
			}
			break;
		}
        try{bc.SaveChecked();}catch(Exception e){}
        BillingController.tes();
	}
}