@isTest
public class TestStore {
	@IsTest
static void Test1() {
		StoreController st = new StoreController();
		st.lead.email='test@test.com';
		st.lead.LastName='test';
		st.lead.Company='test';
		st.SaveLead();
	}
}