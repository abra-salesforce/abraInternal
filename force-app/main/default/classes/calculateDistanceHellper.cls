public with sharing class calculateDistanceHellper {

    @Future(callout=true)
    public static void sendGoogleAndUpdate(set<Id> travelIds){

        List<Travel__c> travels = getListWithFields(travelIds);                                     // get wanted fields with soql
        
        for(Travel__c curT : travels){

            HTTPResponse resp = new HTTPResponse();

            resp =  sendRequestAndGetJsonResults(curT.From__c, curT.To_Address__c);            //get data from google
            
            FromJsonDis test = parse(resp.getBody().replace('\n', ''));                         //get data from json

            Decimal numOfKM;
            if(checkValid(test))
                numOfKM = test.rows[0].elements[0].distance.value/1000.0;
        
            curT.Driving_Distance__c = numOfKM;                                                 //update current travel distance
        }
        update travels;                                                                             //update to salesforce
    }



    //METHODS
    public static List<Travel__c> getListWithFields(Set<Id> relaventObj ){

        return [SELECT Id, From__c, To_Address__c, Driving_Distance__c FROM Travel__c WHERE Id IN : relaventObj];
    }

    public static Boolean checkValid(FromJsonDis test){

        Boolean res = false;

        if(test.status == 'OK'){                                                                //check that is valid

            if(test.rows.size()>0){

                if(test.rows[0].elements.size()>0){

                    cls_elements curElem = test.rows[0].elements[0]; 
                    if(curElem.status == 'OK' && curElem.distance!=null && curElem.distance.value!=null)
                        res = true;
                }
            }
        }
        return res;
    }

    public static HTTPResponse sendRequestAndGetJsonResults( String address1, String address2){
        
        HttpRequest req = new HttpRequest(); Http http = new Http();

        req.setMethod('GET');

        String encodedStringFrom = EncodingUtil.urlEncode(address1,'UTF-8'), encodedStringDest = EncodingUtil.urlEncode(address2,'UTF-8');

        req.setEndPoint('https://maps.googleapis.com/maps/api/distancematrix/json' + '?origins=' + encodedStringFrom + '&destinations=' + encodedStringDest + '&mode=driving' + '&sensor=false' + '&language=en' + '&units=metric' + '&key=AIzaSyAhnO7i9k2fQuAn8dmcaN0_Wyxp3CMa09k');
        
        HTTPResponse response = new HTTPResponse();
        
        if(Test.isRunningTest()==true)
            response.setBody('{"destination_addresses": ["Dizengoff St 9, Tel Aviv-Yafo, Israel"],"origin_addresses": ["Dizengoff St 50, Tel Aviv-Yafo, Israel"], "rows": [{"elements": [{"distance": {"text": "0.5 km", "value": 548 }, "duration": {"text": "3 mins", "value": 178},"status": "OK"}]}], "status": "OK"}');
        else 
            response = http.send(req); 
        
        return response;
    }

    //                                      JSON DESERIALIZE
    public class FromJsonDis{
	    public Cls_rows[] rows;
	    public String status;	//OK
    }
    class Cls_rows {
		public cls_elements[] elements;
	}
	class cls_elements {
		public cls_distance distance;
		public String status;	//OK
	}
	class cls_distance {
		public Decimal value;	//1234
	}
	public static FromJsonDis parse(String json){
		return (FromJsonDis) System.JSON.deserialize(json, FromJsonDis.class);
	}    
}