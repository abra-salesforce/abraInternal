({
    
    
    RemoteFindIDByPhoneT1: function (phone, callStatus, ivrid, callDirection, cmp) {
        //console.log(phone);
        var action = cmp.get("c.FindObjectByPhone");
        action.setParams({ phoneNumber : phone });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            //console.log('state: ' + state);
            if (state === "SUCCESS") {
                // Alert the user with the value returned from the server
                //console.log("From server: " + response.getReturnValue())
                console.log("Test 003");
                
                var coustomerResp = JSON.parse(response.getReturnValue());
                var notificationBar = cmp.find("outName");
                var coustomeDataView;
                if(coustomerResp != null && coustomerResp.Name != null && coustomerResp.Name != "")
                {
                   coustomeDataView = "Incoming Call: " + coustomerResp.Name;
                }
                else
                {
                    console.log(phone);                    
                    coustomeDataView = "Incoming Call: " + phone;
                }
                notificationBar.set("v.value", coustomeDataView);
                
                
                //Clear cash
                window.localStorage.setItem('call-data', '{"vclightniingcalldata":""}');
                if(callStatus == "Talking" || (callStatus == "Dialing" && callDirection == "Click2Call")){
                    try{
                        this.RemoteCreateTaskFromClick2CallT1(response.getReturnValue(), ivrid, cmp,callStatus,callDirection);
                    }catch(RTFC2Cerror){
                        console.log("Error message: " + RTFC2Cerror);
                    }
                }
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
                else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + 
                                        errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
        });
        $A.enqueueAction(action);
    },
    
    GetTaskByID: function (ivrid, ID, cmp) {
        console.log('ivrid', ivrid);
        console.log('ID', ID);
        var action = cmp.get("c.GetTaskDB");
        action.setParams({ paramID : ID});
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            //console.log('state2: ' + state);
            if (cmp.isValid() && state === "SUCCESS") {
                // Alert the user with the value returned from the server2
                //console.log("From server2: " + response.getReturnValue());
                //var notificationBar = cmp.find("outName");
                //notificationBar.set("v.value", response.getReturnValue());
                cmp.set("v.tasks", response.getReturnValue());
                
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
                else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + 
                                        errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
        });
        $A.enqueueAction(action);
    },
    
    RemoteCreateTaskFromClick2CallT1: function (customerData, ivrid, cmp,callStatus,callDirection) {
        try{
            //console.log('ivrid', ivrid);
            var customerData = JSON.parse(customerData);
            //console.log(customerData);
            var action = cmp.get("c.CreateTaskFromClick2Call");
            action.setParams({ ivrUniqueID : ivrid, customerID : customerData.ID, caseId : '' , callType : 'Incoming'});
            
            action.setCallback(this, function(response) {
                var state = response.getState();
                //console.log('state2: ' + state);
                if (state === "SUCCESS") {
                    try
                    {
                        //console.log("From server2: " + response.getReturnValue());
                        var TaskResp = JSON.parse(response.getReturnValue());
                        //console.log(TaskResp.InsertResult);
                        
                        if(typeof(TaskResp.InsertResult) != "string"){                            
                            var isDefined = !$A.util.isUndefined(cmp.get("v.platform"));                            
                            var customerID = TaskResp.CustomerID;
                            if(customerID != null)
                            {
                                                            console.log("Customer Id is:" + customerID);                                                                                                                                                                                                                                                      
                            if(customerID != null && customerID != "NoPopup")
                            {
                                var platform = cmp.get("v.platform");
                                if(platform == "Console")
                                {
                                    console.log("Popup for console");
                                    var open = cmp.get("c.openTab");                            
                                    var recordId = "" + TaskResp.InsertResult.Id;                            
                                    if(recordId != null && recordId != "")
                                    {
                                        cmp.set("v.currentRecordId", recordId);                                        
                                    }                               
                                    
                                    open.setParams({component:cmp, event:null, helper:null});                                          
                                    $A.enqueueAction(open);    
                                }
                                else if(platform == "Classic")
                                {
                                    var host = window.location.host;
                                    var prefix = TaskResp.InsertResult.Id.substring(0,3);
                                    var popupWindow = false;
                                    if(callDirection == "Incoming" ||
                                       (callDirection == "Click2Call" && prefix == "00T" && 
                                        (callStatus == "Talking" || callStatus == "Ringing")))
                                    {
                                        popupWindow = true;
                                    }
                                    console.log("Popup window: " + popupWindow);
                                    console.log("Prefix: " + prefix);
                                    console.log("Popup for - Non Console user ");
                                    console.log("Call Direction: " + callDirection);
                                    console.log("Call Status: " + callStatus);
                                    console.log("Id:" + TaskResp.InsertResult.Id);                                    
                                    if(popupWindow)
                                    {
                                    	window.open('https://'+ host +'/one/one.app#/sObject/'+ TaskResp.InsertResult.Id +'/view');            
                                    }
                                    
                                }                                    
                                    else
                                    {
                                        console.log("ERROR WITH POPUP");
                                        console.log(isDefined);
                                    }                 
                            }
                            else
                            {
                                console.log("No popup, this feature can be changed at your metadata object 'Voicenter Configuration' ");
                            }
                            }
                            else
                            {
                                console.log("No Id.");
							}

                        }                                                
                    }
                    catch(ex){console.log(ex);}
                }
                else if (state === "INCOMPLETE") {
                    // do something
                }
                    else if (state === "ERROR") {
                        var errors = response.getError();
                        if (errors) {
                            if (errors[0] && errors[0].message) {
                                console.log("Error message: " + 
                                            errors[0].message);
                            }
                        } else {
                            console.log("Unknown error");
                        }
                    }
            });
            $A.enqueueAction(action);
        }catch(ex){console.log(ex);}
    }
    
    
    
    
})