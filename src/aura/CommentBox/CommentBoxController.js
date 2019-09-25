({
    doInit : function(component, event, helper) {
        var accessAction = component.get("c.checkAccess");
        accessAction.setParams({
            "readOnly": false
        });

        //Overwrite the public comment to make sure it's true (this is done in Apex too)
        //A tiny bit hacky, but this avoids having to wait for a server response
        //We know it will always be true by default
        component.set("v.publicComment", true);
        component.set("v.attachmentNames", '');

        //See if the user has the rights to use CommentBox
        accessAction.setCallback(this, function(response){
            var access = response.getReturnValue();
            component.set("v.hasAccess", access);
            //If they do have access, get the case information
            //in another callback
            if(access){
                var action = component.get("c.getCase");
	                action.setParams({
                    "caseId": component.get("v.recordId")
                });
                action.setCallback(this, function(response) {
                    var caseRecord = response.getReturnValue();
                    component.set("v.thisCase", caseRecord);
                    //component.set("v.publicComment", caseRecord.publicComment);
                    component.initialiseFollowers();
                });
                $A.enqueueAction(action);
            }
        });
        
        // Invoke the service
        $A.enqueueAction(accessAction);
    },

    handleUploadFinished: function (component, event) {
        // Get the list of uploaded files
        var uploadedFiles = event.getParam("files");
        var JSONstr = JSON.stringify(uploadedFiles);
        var JSONFiles =  JSON.parse(JSONstr);
        
        if(component.get("v.attachmentIds") == null || component.get("v.attachmentIds") == ""){
            var fileNames = '';
            var fileIds =[];
        }else{
            var fileNames = component.get('v.attachmentNames');
            var fileIds =  component.get('v.attachmentIds');
        }

        //Add the file names to output on the screen
        //Add the IDs to be attached (via apex controller on send) to the comment
        for (var i = 0; i < JSONFiles.length; i++) {
            //If we haven't already added this attachment
            if(!fileNames.includes(JSONFiles[i].name)){
                fileNames += JSONFiles[i].name + ', ';
            }
            fileIds.push(JSONFiles[i].documentId);
        }
        component.set('v.attachmentIds', fileIds);
        component.set('v.attachmentNames', fileNames);
    },

    removeAttachments: function(component, event, helper){
        component.set('v.attachmentIds', null);
        component.set('v.attachmentNames', '');  
    },

    togglePublic : function(component, event, helper){
        //Want to change the label of the "Send" button to "Save Internal" or something
        var isPublic = component.get("v.publicComment");
        if(isPublic == true){
            isPublic = false;
            //component.set('send');
        }else{
            isPublic = true;
        }
        component.set("v.publicComment", isPublic);
    },

    handleCaseFollowerUpdate : function(component, event, helper){
        var followersBox = component.find("followers").get("v.value");

        if(followersBox == true){
            var action = component.get("c.getCaseFollowers");        
            action.setParams({
                "caseId": component.get("v.recordId")
            });
            action.setCallback(this, function(response){
                var emails = response.getReturnValue();
                if(emails != ''){
	                component.set("v.followerEmailAddresses", "CC: " + emails + "\n");
                }
            });
            
            $A.enqueueAction(action);
        }else{
            component.set("v.followerEmailAddresses", '');

        }
    },
    
    handleSendMessage : function(component, event, helper) {
		var action = component.get("c.saveCase");
        action.setParams({
            "thisCase": component.get("v.thisCase"),
            "attachments":component.get("v.attachmentIds")
        });
        action.setCallback(this, function(response){
            var successMessage = response.getReturnValue();
            var resultsToast = $A.get("e.force:showToast");
            if(successMessage == 'Comment Sent!' || successMessage == 'Private Comment Saved!'){
                var type="success";
            }else if(successMessage.includes('System.EmailException')){
                var type="error";
            }else{
                var type="warning";
            }
            resultsToast.setParams({
                "title": "CommentBox",
                "message": successMessage,
                "type": type
            });
            resultsToast.fire();
        });
        $A.enqueueAction(action);    	
    },

    validateEmail : function(component, event, helper) {
        var isValidEmail = true; 
        var elementId = event.getSource().getLocalId();
        var emailField = component.find(elementId);
        var sendButton = component.find("send");
        var str = emailField.get("v.value");
        var emailFieldValue = str.split(";");
        var regExpEmailformat = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;  
        
        for(var x in emailFieldValue){
            if(emailFieldValue[x].match(regExpEmailformat) || ($A.util.isEmpty(emailFieldValue[x]))){
                //emailField.set("v.errors", [{message: null}]);
                $A.util.removeClass(emailField, 'slds-has-error');
                component.set("v.disabled", false);
                isValidEmail = true;
            }else{
                $A.util.addClass(emailField, 'slds-has-error');
                component.set("v.disabled", true);
                isValidEmail = false;
            }
        }
    },

    handleTemplateBody : function(component, event, helper){
        component.set("{!v.thisCase.CommentBox__Comment_Body__c}", event.getParam("message"));
    }    
})