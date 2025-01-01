({
	doInit : function(component, event, helper) {
		var action = component.get("c.getContentDocs");
		action.setParams({
            "arecordId": component.get("v.strid")
        });
		action.setCallback(this, function(response) {
			var state = response.getState();
			console.log(response.getReturnValue());
			if(state === 'SUCCESS') {
				component.set("v.items", response.getReturnValue()); 
			}
		});
		$A.enqueueAction(action);
        
	},
    previewFile :function(c,e,h){
		var selectedPillId = e.getSource().get("v.name");
		console.log('id:'+selectedPillId);
		$A.get('e.lightning:openFiles').fire({
			recordIds: [selectedPillId]
		});
	}
})