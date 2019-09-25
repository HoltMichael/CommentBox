({
    onCometdLoaded : function(component, event, helper) {
        var cometd = new org.cometd.CometD();
        component.set('v.cometd', cometd);
        if (component.get('v.sessionId') != null){
          helper.connectCometd(component);
        }
    },

    onInit : function(component, event, helper) {
        var accessAction = component.get("c.checkAccess");

        accessAction.setCallback(this, function(response){
            var access = response.getReturnValue();
            component.set("v.hasAccess", access);
        });

        //Initialise components
        component.set('v.cometdSubscriptions', []);
        component.set('v.notifications', []);
        component.set("v.buttonLabel", 'Turn Notifications Off');
        

        // Retrieve session id
        var action = component.get('c.getSessionId');
        action.setCallback(this, function(response) {
          if (component.isValid() && response.getState() === 'SUCCESS') {
            component.set('v.sessionId', response.getReturnValue());
            if (component.get('v.cometd') != null)
              helper.connectCometd(component);
          }
          else
            console.error(response);
        });
        $A.enqueueAction(action);
        $A.enqueueAction(accessAction);
        helper.displayToast(component, 'success', 'Ready to receive notifications.');
    },
    
    toggleConnection : function(component, event, helper){
        if(component.get("v.isMuted") === true){
            component.set("v.isMuted", false);
            component.set("v.buttonLabel", 'Turn Notifications Off');
        }else{
            component.set("v.isMuted", true);
            component.set("v.buttonLabel", "Turn Notifications On");
        }
    },
})