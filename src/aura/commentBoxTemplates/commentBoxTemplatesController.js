// Controller
({
    /*
     * Initialise the available folder options
     * */
    doInit: function(component, event, helper) {
        // Request from server
        var action = component.get("c.getFolders");
        action.setCallback(this, function(result){
            var folders = result.getReturnValue();
            component.set("v.folders", folders);
        });
        $A.enqueueAction(action);
    },
    
    /*
     * When an email folder is select, check to see if it's "none"
     * If it's not "none", then get the emails in that folder and make
     * them available in the next picklist
     * */
    handleFolderSelection: function(component, event, helper){
    	var selection = component.find("folderOption").get("v.value");
        console.log(selection);
        if(selection != 'None'){          
        	var action = component.get("c.getTemplates");
	         action.setParams({
    	        "folderId": selection
        	});
            action.setCallback(this, function(result){
                var emails = result.getReturnValue();
                console.log(emails);
                component.set("v.emails", emails);
            });
            $A.enqueueAction(action);
            component.set("v.folderSelected", "true");
        }else{
            component.set("v.folderSelected", "false");
            var bodyEvent = component.getEvent("templateBodyRetrieved");
            bodyEvent.setParams({"message" : ""}).fire();
        }
	},
    
    handleEmailSelection: function(component, event, helper){
    	var selection = component.find("emailOption").get("v.value");
        	var action = component.get("c.getEmailBody");
	         action.setParams({
    	        "emailId": selection
        	});
            action.setCallback(this, function(result){
                var email = result.getReturnValue();
				var bodyEvent = component.getEvent("templateBodyRetrieved");
                bodyEvent.setParams({"message" : email}).fire();
            });
            $A.enqueueAction(action);
    }
})