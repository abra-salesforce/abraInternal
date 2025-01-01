({
       /*
    afterScriptsLoaded: function () {
        window.voicenterUserCode = '{!$User.VoicenterUserCode__c}';
        window.voicenterOrgCode = '{!$User.VoicenterOrgCode__c}';
      	},
    */
    onLoad: function (cmp, event, helper){
        window.localStorage.setItem('call-data', '{"vclightniingcalldata":""}');		
        var countdownTimer = 10;        		        
        window.setInterval(
            $A.getCallback(function() { 
                try{               
				//Close panel after 10 sec
                var utilityAPI = cmp.find("utilitybar");
       			utilityAPI.getUtilityInfo().then(function(response) {
            		if (response.utilityVisible) {
                        if(countdownTimer > 0){
                            countdownTimer--;
                        }else{
                        	utilityAPI.minimizeUtility();
                            countdownTimer = 10;
                        }
           			}
       			})
        		.catch(function(error) {
            		console.log(error);
        		});
                
            	var callData = JSON.parse(window.localStorage.getItem('call-data'));
                
        		if(callData.vclightniingcalldata && callData.vclightniingcalldata != 'undefined'){
                    console.log(callData.vclightniingcalldata);
                    var isInConsole = cmp.get('c.isConsoleNavigation');
                            isInConsole.setParams({component:cmp, event:null, helper:null});  
                    $A.enqueueAction(isInConsole);
                    // This if is for Not opening the utility bar for the C2C calls                    
                    console.log("Direction: " + callData.vclightniingcalldata.direction); 
                    console.log("Call Status: " + callData.vclightniingcalldata.callstatus);
                    if(!(callData.vclightniingcalldata.direction == 'OutgoingC2C' && 
                         (callData.vclightniingcalldata.callstatus == 'Talking' || callData.vclightniingcalldata.callstatus == 'Dialing') 
                         )) { utilityAPI.openUtility(); }                     
                    helper.RemoteFindIDByPhoneT1(callData.vclightniingcalldata.callerphone, callData.vclightniingcalldata.callstatus, callData.vclightniingcalldata.ivrid, callData.vclightniingcalldata.direction, cmp);
        		}
                }catch(Ex){ console.log(Ex);}
            }), 1000
        );      
    },
    
    handleComponentEvent : function(cmp, event) {
        var message = event.getParam("message");
 
        console.log('from event', cmp.get("v.message"));

    },
    
    itemsChange: function(cmp, evt) {
        console.log("numItems has changed");
        //console.log("old value: " + evt.getParam("oldValue"));
        //console.log("current value: " + evt.getParam("value"));
    },
 
     getInput: function(cmp, evt) {
         var myName = cmp.find("name").get("v.value");
         //window.localStorage.setItem('call-data', "");
         window.pashaStorage = {};
         console.log(window.localStorage.getItem(myName));
         //$A.log('testA');
         
        
        var myText = cmp.find("outName");
        var greet = "Hi, " + myName;
        myText.set("v.value", greet);
         
    },
    
	parseFindIDByPhone: function (result) {
	var data = {};
	if(typeof(Storage) !== "undefined"){
		var calls = localStorage.getItem("voicenterCallsLog");
		if(calls != null){
			calls = JSON.parse(calls);
			for(var callLength = calls.length, callIDX = 0; callIDX < callLength; callIDX++){
				var call = calls[callIDX];
				if(call.callerphone == result.Phone && result.ID != undefined){
					call.clientID = result.ID;
					call.clientSearched = true;
					data.ivrid = calls.ivrid;
				}
				calls[callIDX] = call;
			}
			localStorage.setItem("voicenterCallsLog", JSON.stringify(calls));
		}
	}
		
	data.callername = result.Name || "";
	data.callerphone = result.Phone;
	data.ivrid = result.ID;
	window.voicenterNotify(data);
	},
    

    
    //Please do not delete this working example, you can comment or move if you want, Thx. Pavel
    jsLoad: function () {
    	//VCMain.prtFunc();
        //VCMain.prtFunc2();

	},
    
    jsLoadSocket : function () {
        
    },
    
    jsLoad2: function () {

	},
    
        openTab : function(component, event, helper) {           	
            var id = component.get("v.currentRecordId");            
        var workspaceAPI = component.find("workspace");
        workspaceAPI.openTab({
            recordId:id,
            focus: true
        }).then(function(response) {
            workspaceAPI.getTabInfo({
                  tabId: response
            }).then(function(tabInfo) {
            console.log("The url for this tab is: " + tabInfo.url);
            });
        })
        .catch(function(error) {
               console.log(error);
        });
    },        
	            
    isConsoleNavigation : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.isConsoleNavigation().then(function(response) {
            if(response) { component.set("v.platform", "Console");}
            else { component.set("v.platform", "Classic");}                                     
       })
        .catch(function(error) {
            console.log(error);
        });
       
    }


    //end
})