@isTest
private class TestDistanceGoogleTrigger {

    @isTest static void createTravelWithGoodInfo(){
    
        Travel__c travel = new Travel__c();
        travel.From__c = 'Dizengoff St 50, Tel Aviv-Yafo, Israelf'; travel.To_Address__c = 'Yigal Alon St, Tel Aviv-Yafo, Israel';

        insert travel;
    }
}