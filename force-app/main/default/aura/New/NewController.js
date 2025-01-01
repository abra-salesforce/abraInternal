({
    doInit1 : function (component, event, helper) {
        component.set("v.Name", null);
        var currentTime = new Date();
        var action = component.get("c.getContact");
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.Name", response.getReturnValue());
            }
            var createRecordEvent = $A.get("e.force:createRecord");
            createRecordEvent.setParams({
                "entityApiName": "Working_Days__c",
                "defaultFieldValues": {
                    "Performed_By_contact__c": component.get("v.Name")
                }
            });
            createRecordEvent.fire();
        });
        $A.enqueueAction(action);
    },
    doInit2 : function (component, event, helper) {
        component.set("v.Name", null);
        var currentTime = new Date();
        var action = component.get("c.getContact");
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.Name", response.getReturnValue());
            }
            var createRecordEvent = $A.get("e.force:createRecord");
            createRecordEvent.setParams({
                "entityApiName": "Working_Hours__c",
                "recordTypeId": "012b00000001AC7AAM",
                "defaultFieldValues": {
                    "Performed_By_2__c": component.get("v.Name"),
                    "Date__c": currentTime    
                }
            });
            createRecordEvent.fire();
        });
        $A.enqueueAction(action);
    },
    doInit3 : function (component, event, helper) {
        component.set("v.Name", null);
        var currentTime = new Date();
        var action = component.get("c.getContact");
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.Name", response.getReturnValue());
            }
            var createRecordEvent = $A.get("e.force:createRecord");
            createRecordEvent.setParams({
                "entityApiName": "Working_Hours__c",
                "recordTypeId": "012b00000001AC2AAM",
                "defaultFieldValues": {
                    "Performed_By_2__c": component.get("v.Name"),
                    "Date__c": currentTime    
                }
            });
            createRecordEvent.fire();
        });
        $A.enqueueAction(action);
    }
})